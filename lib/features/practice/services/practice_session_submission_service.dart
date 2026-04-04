import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jahiz/features/practice/models/practice_evaluation.dart';

class PracticeSessionSubmissionService {
  PracticeSessionSubmissionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> saveCompletedSession({
    required String uid,
    required String userRole,
    required String userLevel,
    required List<String> techStack,
    required String? sessionRole,
    required String? selectedRole,
    required List<String> questions,
    required Map<int, String> answers,
    required Map<int, PracticeEvaluation> evaluations,
    required double averageScore,
  }) async {
    final sessionRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('practiceSessions')
        .doc();

    final now = DateTime.now().toUtc();
    final sessionRoleValue = sessionRole?.trim() ?? '';
    final selectedRoleValue = selectedRole?.trim() ?? '';
    final practiceJob = sessionRoleValue.isNotEmpty
        ? sessionRoleValue
        : (selectedRoleValue.isNotEmpty ? selectedRoleValue : userRole);

    final questionResults = <Map<String, dynamic>>[];
    final weakQuestions = <Map<String, dynamic>>[];

    for (var i = 0; i < questions.length; i++) {
      final evaluation = evaluations[i];
      if (evaluation == null) {
        continue;
      }

      final question = questions[i];
      final questionScorePercent = (evaluation.score * 10)
          .clamp(0, 100)
          .toDouble();

      questionResults.add(<String, dynamic>{
        'questionIndex': i,
        'question': question,
        'answer': (answers[i] ?? '').trim(),
        'score': evaluation.score,
        'scorePercent': questionScorePercent,
        'feedback': evaluation.feedback,
        'modelAnswer': evaluation.modelAnswer,
        'topic': _inferTopic(
          question: question,
          techStack: techStack,
          fallbackTopic: practiceJob,
        ),
      });

      if (questionScorePercent < 50) {
        weakQuestions.add(<String, dynamic>{
          'question': question,
          'scorePercent': questionScorePercent,
        });
      }
    }

    await sessionRef.set(<String, dynamic>{
      'role': practiceJob,
      'practiceJob': practiceJob,
      'level': userLevel,
      'techStack': techStack,
      'totalQuestions': questions.length,
      'answeredQuestions': questionResults.length,
      'averageScore': averageScore,
      'averageScorePercent': (averageScore * 10).clamp(0, 100).toDouble(),
      'questionResults': questionResults,
      'weakQuestions': weakQuestions,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': Timestamp.fromDate(now),
    });
  }

  String _inferTopic({
    required String question,
    required List<String> techStack,
    required String fallbackTopic,
  }) {
    final normalizedQuestion = question.toLowerCase();

    final normalizedFallback = fallbackTopic.trim().toLowerCase();
    if (normalizedFallback.isNotEmpty &&
        normalizedQuestion.contains(normalizedFallback)) {
      return fallbackTopic;
    }

    for (final topic in techStack) {
      final normalizedTopic = topic.trim().toLowerCase();
      if (normalizedTopic.isEmpty) {
        continue;
      }
      if (normalizedQuestion.contains(normalizedTopic)) {
        return topic;
      }
    }

    if (fallbackTopic.trim().isNotEmpty) {
      return fallbackTopic;
    }

    return techStack.isNotEmpty ? techStack.first : 'General';
  }
}
