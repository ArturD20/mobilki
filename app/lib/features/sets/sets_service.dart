import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/env.dart';
import 'leitner_scheduler.dart';

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

  static Stream<QuerySnapshot<Map<String, dynamic>>> setsByLanguageStream(String language) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _sets()
        .where('ownerUid', isEqualTo: uid)
        .where('language', isEqualTo: language)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

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

  static Stream<List<LeitnerCardState>> leitnerCardsStream(String setId) {
    return _sets().doc(setId).snapshots().asyncExpand((setDoc) {
      if (!setDoc.exists) return Stream.value([]);
      final data = setDoc.data()!;
      final isVirtual = data['isVirtual'] == true;
      final globalSetId = data['fromGlobalSetId'] as String?;

      if (isVirtual && globalSetId != null) {
        return _combineVirtualStreams(globalSetId, setId);
      } else {
        return _cardsCol(setId).snapshots().map((snap) {
          return snap.docs.map((d) => LeitnerCardState.fromDoc(d)).toList();
        });
      }
    });
  }

  static Stream<List<LeitnerCardState>> _combineVirtualStreams(String globalSetId, String localSetId) {
    late StreamController<List<LeitnerCardState>> controller;
    
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? globalDocs;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? localDocs;

    StreamSubscription? globalSub;
    StreamSubscription? localSub;

    void emit() {
      if (globalDocs == null) return;
      
      final localMap = {for (var d in (localDocs ?? [])) d.id: d.data()};

      final combined = globalDocs!.map((gDoc) {
         final gData = gDoc.data();
         final lData = localMap[gDoc.id] ?? {};
         
         final box = (lData['leitnerBox'] is int) ? lData['leitnerBox'] as int : 1;
         
         DateTime? nextReview;
         final ts = lData['nextReviewAt'];
         if (ts is Timestamp) nextReview = ts.toDate();
         else if (ts is DateTime) nextReview = ts;
         
         return LeitnerCardState(
           id: gDoc.id,
           front: (gData['front'] ?? '').toString(),
           back: (gData['back'] ?? '').toString(),
           box: box,
           nextReviewAt: nextReview,
         );
      }).toList();
      
      controller.add(combined);
    }

    controller = StreamController<List<LeitnerCardState>>(
      onListen: () {
        globalSub = _globalSets().doc(globalSetId).collection('cards').snapshots().listen((snap) {
          globalDocs = snap.docs;
          emit();
        });
        localSub = _sets().doc(localSetId).collection('cards').snapshots().listen((snap) {
          localDocs = snap.docs;
          emit();
        });
      },
      onCancel: () {
        globalSub?.cancel();
        localSub?.cancel();
      },
    );

    return controller.stream;
  }

  static Future<void> updateCardLeitnerState({
    required String setId,
    required String cardId,
    required int box,
    required DateTime nextReviewAt,
  }) async {
    await _cardsCol(setId).doc(cardId).set({
      'leitnerBox': box,
      'nextReviewAt': Timestamp.fromDate(nextReviewAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateSetStatistics({
    required String setId,
    required int correct,
    required int wrong,
  }) async {
    await _sets().doc(setId).update({
      'correctCount': FieldValue.increment(correct),
      'wrongCount': FieldValue.increment(wrong),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSetLatestResult({
    required String setId,
    required int correct,
    required int wrong,
  }) async {
    await _sets().doc(setId).update({
      'latestCorrect': correct,
      'latestWrong': wrong,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSessionProgress({
    required String setId,
    required int index,
    required int correct,
    required int wrong,
    required List<String> wrongIds,
  }) async {
    await _sets().doc(setId).update({
      'sessionProgress': {
        'index': index,
        'correct': correct,
        'wrong': wrong,
        'wrongIds': wrongIds,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> clearSessionProgress(String setId) async {
    await _sets().doc(setId).update({
      'sessionProgress': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static CollectionReference<Map<String, dynamic>> _globalSets() =>
      _firestore.collection('global_sets');

  static Stream<QuerySnapshot<Map<String, dynamic>>> globalSetsStream() {
    return _globalSets().orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> globalSetsByLanguageStream(String language) {
    return _globalSets()
        .where('language', isEqualTo: language)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> globalCardsStream(String globalSetId) {
    return _globalSets().doc(globalSetId).collection('cards').snapshots();
  }

  static Future<String?> findSetIdByGlobalId(String globalSetId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final existing = await _sets()
        .where('ownerUid', isEqualTo: uid)
        .get();
    
    final match = existing.docs.where((doc) => doc.data()['fromGlobalSetId'] == globalSetId).firstOrNull;
    return match?.id;
  }

  static Future<String> copyGlobalSet(String globalSetId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Nie zalogowano');

    final existing = await _sets()
        .where('ownerUid', isEqualTo: uid)
        .get();
    
    final match = existing.docs.where((doc) => doc.data()['fromGlobalSetId'] == globalSetId).firstOrNull;
    
    if (match != null) {
      return match.id;
    }

    final globalSetDoc = await _globalSets().doc(globalSetId).get();
    if (!globalSetDoc.exists) throw StateError('Zestaw nie istnieje');
    final data = globalSetDoc.data()!;

    final newSetRef = await _sets().add({
      'title': data['title'],
      'language': data['language'],
      'ownerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'cards': data['cards'] ?? 0,
      'fromGlobalSetId': globalSetId,
      'isVirtual': true, 
    });
    
    return newSetRef.id;
  }

  static Future<void> seedGlobalSets() async {
    // Przykładowe dane dla wszystkich wspieranych języków - dodawane sa na backend, ale chwilowo sa tu, bo firebase jest jako emulator
    final setsToSeed = [
      {
        'title': 'Angielski: Podstawowe zwroty',
        'language': 'Angielski',
        'cards': [
          {'front': 'Hello', 'back': 'Cześć'},
          {'front': 'Good morning', 'back': 'Dzień dobry'},
          {'front': 'Thank you', 'back': 'Dziękuję'},
          {'front': 'How are you?', 'back': 'Jak się masz?'},
          {'front': 'Goodbye', 'back': 'Do widzenia'},
        ]
      },
      {
        'title': 'Niemiecki: Kolory',
        'language': 'Niemiecki',
        'cards': [
          {'front': 'Rot', 'back': 'Czerwony'},
          {'front': 'Blau', 'back': 'Niebieski'},
          {'front': 'Grün', 'back': 'Zielony'},
          {'front': 'Schwarz', 'back': 'Czarny'},
          {'front': 'Weiß', 'back': 'Biały'},
        ]
      },
      {
        'title': 'Hiszpański: Liczby 1-5',
        'language': 'Hiszpański',
        'cards': [
          {'front': 'Uno', 'back': 'Jeden'},
          {'front': 'Dos', 'back': 'Dwa'},
          {'front': 'Tres', 'back': 'Trzy'},
          {'front': 'Cuatro', 'back': 'Cztery'},
          {'front': 'Cinco', 'back': 'Pięć'},
        ]
      },
      {
        'title': 'Francuski: Powitania',
        'language': 'Francuski',
        'cards': [
          {'front': 'Bonjour', 'back': 'Dzień dobry'},
          {'front': 'Salut', 'back': 'Cześć'},
          {'front': 'Au revoir', 'back': 'Do widzenia'},
          {'front': 'Merci', 'back': 'Dziękuję'},
          {'front': 'Oui', 'back': 'Tak'},
        ]
      },
      {
        'title': 'Włoski: Jedzenie',
        'language': 'Włoski',
        'cards': [
          {'front': 'Pizza', 'back': 'Pizza'},
          {'front': 'Pasta', 'back': 'Makaron'},
          {'front': 'Vino', 'back': 'Wino'},
          {'front': 'Formaggio', 'back': 'Ser'},
          {'front': 'Pane', 'back': 'Chleb'},
        ]
      },
      {
        'title': 'Japoński: Podstawy',
        'language': 'Japoński',
        'cards': [
          {'front': 'Konnichiwa', 'back': 'Dzień dobry'},
          {'front': 'Arigatou', 'back': 'Dziękuję'},
          {'front': 'Sayonara', 'back': 'Do widzenia'},
          {'front': 'Hai', 'back': 'Tak'},
          {'front': 'Iie', 'back': 'Nie'},
        ]
      },
    ];

    for (final set in setsToSeed) {
      final existing = await _globalSets().where('title', isEqualTo: set['title']).limit(1).get();
      if (existing.docs.isNotEmpty) continue;

      final setRef = await _globalSets().add({
        'title': set['title'],
        'language': set['language'],
        'createdAt': FieldValue.serverTimestamp(),
        'cards': (set['cards'] as List).length,
      });

      final batch = _firestore.batch();
      for (final card in (set['cards'] as List)) {
        final cardRef = _globalSets().doc(setRef.id).collection('cards').doc();
        batch.set(cardRef, {
          'front': card['front'],
          'back': card['back'],
          'createdAt': FieldValue.serverTimestamp(), 
        });
      }
      await batch.commit();
    }
  }

  static Future<void> checkAndAddStarterSets() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDocRef = _firestore.collection('users').doc(uid);
    final userDoc = await userDocRef.get();

    if (userDoc.exists && (userDoc.data()?['starterSetsAdded'] == true)) {
      return; 
    }

    final globalSetsSnap = await _globalSets().get();
    if (globalSetsSnap.docs.isEmpty) {

      await seedGlobalSets();
      final retrySnap = await _globalSets().get();
      if (retrySnap.docs.isEmpty) return; 
      
      for (final gs in retrySnap.docs) {
        await copyGlobalSet(gs.id);
      }
    } else {
      for (final gs in globalSetsSnap.docs) {
        await copyGlobalSet(gs.id);
      }
    }

    await userDocRef.set({'starterSetsAdded': true}, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getSessionProgress(String setId) async {
    final doc = await _sets().doc(setId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || !data.containsKey('sessionProgress')) return null;
    return data['sessionProgress'] as Map<String, dynamic>?;
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

    final rawBody = utf8.decode(resp.bodyBytes);
    final body = jsonDecode(rawBody) as Map<String, dynamic>;
    final content = (body['choices']?[0]?['message']?['content']) as String?;
    if (content == null) throw StateError('Empty LLM response');

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