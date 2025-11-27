import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/env.dart';

class SetsService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _sets() =>
      _firestore.collection('sets');

  static Future<String> addSet({
    required String title,
    required String language,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Nie zalogowano');
    final doc = await _sets().add({
      'title': title.trim(),
      'language': language,
      'ownerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'cards': 0,
    });
    return doc.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> mySetsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _sets()
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- DODAJ TĘ NOWĄ METODĘ ---
  static Stream<QuerySnapshot<Map<String, dynamic>>> setsByLanguageStream(String language) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Jeśli użytkownik nie jest zalogowany, zwróć pusty strumień
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    
    // Zwróć strumień zestawów, które pasują do języka ORAZ do ID użytkownika
    return _sets()
        .where('ownerUid', isEqualTo: uid)
        .where('language', isEqualTo: language) // <-- Kluczowe filtrowanie
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  // --- KONIEC NOWEJ METODY ---
  
  static CollectionReference<Map<String, dynamic>> _cardsCol(String setId) =>
      _sets().doc(setId).collection('cards');

  static Future<void> addCard({
    required String setId,
    required String front,
    required String back,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Nie zalogowano');

    await _cardsCol(setId).add({
      'front': front.trim(),
      'back': back.trim(),
      'ownerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sets().doc(setId).update({
      'cards': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> cardsStream(String setId) {
    return _cardsCol(setId).orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> updateCardLeitnerState({
    required String setId,
    required String cardId,
    required int box,
    required DateTime nextReviewAt,
  }) async {
    await _cardsCol(setId).doc(cardId).update({
      'leitnerBox': box,
      'nextReviewAt': Timestamp.fromDate(nextReviewAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> generateCardsViaLLM({
    required String setId,
    required int count,
    String? topic,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Nie zalogowano');
    if (count <= 0 || count > 100) throw ArgumentError.value(count, 'count', 'Must be 1..100');

    final setSnapshot = await _sets().doc(setId).get();
    final setData = setSnapshot.data() ?? <String, dynamic>{};
    final language = (setData['language'] as String?) ?? 'English';

    final apiKey = Env.openaiApiKey;
    if (apiKey.startsWith('PUT_')) {
      throw StateError('Ustaw Env.openaiApiKey w lib/core/env.dart');
    }

    final prompt = '''
Generate $count concise flashcards for language: $language
Topic: $topic
Return a valid JSON array ONLY, where each item is an object:
{"front": "<question/word>", "back": "<answer/translation>"}
Do not include any extra text.
''';

    final resp = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant that outputs JSON.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 1500,
      }),
    );

    if (resp.statusCode != 200) {
      throw StateError('LLM error: ${resp.statusCode} ${utf8.decode(resp.bodyBytes)}');
    }

    // Bezpieczne dekodowanie w UTF-8
    final rawBody = utf8.decode(resp.bodyBytes);
    final body = jsonDecode(rawBody) as Map<String, dynamic>;
    final content = (body['choices']?[0]?['message']?['content']) as String?;
    if (content == null) throw StateError('Empty LLM response');

    // Spróbuj sparsować odpowiedź jako JSON (również dekodując ewentualne znaki)
    late List<dynamic> cards;
    try {
      cards = jsonDecode(content) as List<dynamic>;
    } catch (e) {
      final start = content.indexOf('[');
      final end = content.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) throw StateError('Niepoprawny JSON od LLM');
      final sub = content.substring(start, end + 1);
      cards = jsonDecode(sub) as List<dynamic>;
    }

    if (cards.isEmpty) return;

    final batch = _firestore.batch();
    var added = 0;
    for (final c in cards) {
      if (c is Map) {
        final front = (c['front'] ?? '').toString();
        final back = (c['back'] ?? '').toString();
        final docRef = _cardsCol(setId).doc();
        batch.set(docRef, {
          'front': front,
          'back': back,
          'ownerUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        added++;
      }
    }

    if (added > 0) {
      batch.update(_sets().doc(setId), {
        'cards': FieldValue.increment(added),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    }
  }
}