import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumWriteResult {
  const PremiumWriteResult({required this.alreadyPremium});

  final bool alreadyPremium;
}

class PremiumFirebaseService {
  PremiumFirebaseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  String _requireAuthenticatedUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }
    return uid;
  }

  Future<bool> isCurrentUserPremium() async {
    final uid = _requireAuthenticatedUid();
    final snapshot = await _userRef(uid).get();
    final data = snapshot.data() ?? <String, dynamic>{};
    return data['isPremium'] == true;
  }

  Future<PremiumWriteResult> markCurrentUserPremium() async {
    final uid = _requireAuthenticatedUid();
    final ref = _userRef(uid);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? <String, dynamic>{};

      if (data['isPremium'] == true) {
        return const PremiumWriteResult(alreadyPremium: true);
      }

      transaction.set(ref, {
        'isPremium': true,
        'premiumActivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return const PremiumWriteResult(alreadyPremium: false);
    });
  }
}
