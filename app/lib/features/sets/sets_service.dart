import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetsService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _sets() =>
      _firestore.collection('sets');

  static Future<String> addSet({required String title}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Nie zalogowano');
    final doc = await _sets().add({
      'title': title.trim(),
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
}
