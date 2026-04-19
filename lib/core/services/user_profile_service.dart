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

  Future<void> ensureUserDocumentDefaults({
    required String uid,
    required String? email,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final ref = _userRef(uid);
      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? <String, dynamic>{};
      final update = <String, dynamic>{};

      if (data['isPremium'] == null) {
        update['isPremium'] = false;
      }

      final existingEmail = (data['email'] as String?)?.trim() ?? '';
      final incomingEmail = email?.trim() ?? '';
      if (existingEmail.isEmpty && incomingEmail.isNotEmpty) {
        update['email'] = incomingEmail;
      }

      if (data['createdAt'] == null) {
        update['createdAt'] = FieldValue.serverTimestamp();
      }

      if (update.isNotEmpty) {
        transaction.set(ref, update, SetOptions(merge: true));
      }
    });
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
      final existingData = snapshot.data() ?? <String, dynamic>{};
      final existingCreatedAt = existingData['createdAt'];
      final existingIsPremium = existingData['isPremium'];

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
        'isPremium': existingIsPremium is bool ? existingIsPremium : false,
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateCareerProfile({
    required String uid,
    required String role,
    required String level,
    required List<String> technicalStack,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final ref = _userRef(uid);
      final snapshot = await transaction.get(ref);
      final existingData = snapshot.data() ?? <String, dynamic>{};
      final existingCareerTarget =
          existingData['careerTarget'] as Map<String, dynamic>? ??
          <String, dynamic>{};

      final cleanedStack = technicalStack
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();

      transaction.set(ref, {
        'careerTarget': {
          ...existingCareerTarget,
          'targetRole': role.trim(),
          'level': level.trim(),
        },
        'technicalStack': cleanedStack,
      }, SetOptions(merge: true));
    });
  }
}
