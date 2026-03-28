import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) {
    return _userRef(uid).get();
  }

  Future<bool> hasCompletedOnboarding(String uid) async {
    final snapshot = await _userRef(uid).get();
    if (!snapshot.exists) {
      return false;
    }

    final data = snapshot.data();
    if (data == null) {
      return false;
    }

    final userType = data['userType'] as String?;
    final interviewLanguage = data['interviewLanguage'] as String?;
    final technicalStack = data['technicalStack'] as List<dynamic>?;

    return userType != null &&
        interviewLanguage != null &&
        technicalStack != null &&
        technicalStack.length >= 3;
  }

  Future<void> saveOnboardingData({
    required String uid,
    required String email,
    required String userType,
    required Map<String, dynamic> studentInfo,
    required Map<String, dynamic> professionalInfo,
    required Map<String, dynamic> careerTarget,
    required List<String> technicalStack,
    required Map<String, dynamic> socialLinks,
    required String interviewLanguage,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final ref = _userRef(uid);
      final snapshot = await transaction.get(ref);
      final existingCreatedAt = snapshot.data()?['createdAt'];

      transaction.set(ref, {
        'userType': userType,
        'studentInfo': studentInfo,
        'professionalInfo': professionalInfo,
        'careerTarget': careerTarget,
        'technicalStack': technicalStack,
        'socialLinks': socialLinks,
        'interviewLanguage': interviewLanguage,
        'createdAt': existingCreatedAt ?? FieldValue.serverTimestamp(),
        'email': email,
      }, SetOptions(merge: true));
    });
  }
}
