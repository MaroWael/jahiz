import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/practice/presentation/cubit/practice_cubit.dart';
import 'package:jahiz/features/practice/presentation/cubit/practice_state.dart';

enum _ExitChoice { save, discard, cancel }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeCubit _cubit;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = PracticeCubit()..initialize();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<bool> _handleExitAttempt() async {
    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit Practice?'),
          content: const Text(
            'Do you want to save your progress before leaving this practice session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_ExitChoice.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_ExitChoice.discard),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_ExitChoice.save),
              child: const Text('Save Progress'),
            ),
          ],
        );
      },
    );

    if (choice == _ExitChoice.save) {
      await _cubit.saveProgress();
      return true;
    }
    if (choice == _ExitChoice.discard) {
      await _cubit.discardProgress();
      return true;
    }
    return false;
  }

  Widget _buildLoadingShimmer() {
    Widget shimmerBlock({double height = 18}) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.3, end: 0.85),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Container(
            height: height,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade300.withValues(alpha: value),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shimmerBlock(height: 20),
          shimmerBlock(height: 20),
          shimmerBlock(height: 20),
          const SizedBox(height: 12),
          shimmerBlock(height: 140),
          const SizedBox(height: 12),
          shimmerBlock(height: 48),
        ],
      ),
    );
  }

  Widget _buildTimeout(PracticeState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_tethering_error_rounded, size: 50),
            const SizedBox(height: 10),
            Text(
              state.errorMessage ?? 'The request timed out.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cubit.retryLoadingQuestions,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(PracticeState state) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<int>(state.currentIndex),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E9EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${state.currentIndex + 1} of ${state.questions.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.currentQuestion,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationCard(PracticeState state) {
    final evaluation = state.currentEvaluation;
    if (evaluation == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score: ${evaluation.score.toStringAsFixed(1)} / 10',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            'Detailed Feedback',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(evaluation.feedback, style: const TextStyle(height: 1.35)),
          const SizedBox(height: 10),
          const Text('Model Answer', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(evaluation.modelAnswer, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PracticeCubit>.value(
      value: _cubit,
      child: BlocConsumer<PracticeCubit, PracticeState>(
        listenWhen: (previous, current) =>
            previous.currentIndex != current.currentIndex ||
            previous.currentAnswer != current.currentAnswer,
        listener: (context, state) {
          if (_answerController.text != state.currentAnswer) {
            _answerController.value = TextEditingValue(
              text: state.currentAnswer,
              selection: TextSelection.collapsed(
                offset: state.currentAnswer.length,
              ),
            );
          }
        },
        builder: (context, state) {
          return WillPopScope(
            onWillPop: _handleExitAttempt,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Practice Interview'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () async {
                    final canExit = await _handleExitAttempt();
                    if (canExit && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              body: state.isLoadingQuestions
                  ? _buildLoadingShimmer()
                  : state.isTimeout && !state.hasQuestions
                  ? _buildTimeout(state)
                  : state.errorMessage != null && !state.hasQuestions
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _cubit.retryLoadingQuestions,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildQuestionCard(state),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _answerController,
                            minLines: 6,
                            maxLines: 10,
                            onChanged: _cubit.updateCurrentAnswer,
                            decoration: InputDecoration(
                              labelText: 'Your answer',
                              hintText:
                                  'Explain your thought process clearly and use concrete examples.',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Minimum ${PracticeCubit.minCharacters} characters • Current ${state.currentAnswer.trim().length}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          if (state.validationError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              state.validationError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              state.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : _cubit.submitCurrentAnswer,
                              child: state.isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Submit For AI Feedback'),
                            ),
                          ),
                          _buildEvaluationCard(state),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: state.currentIndex == 0
                                      ? null
                                      : _cubit.previousQuestion,
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  label: const Text('Previous'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      state.currentIndex >= state.questions.length - 1
                                      ? null
                                      : _cubit.nextQuestion,
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  label: const Text('Next'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
