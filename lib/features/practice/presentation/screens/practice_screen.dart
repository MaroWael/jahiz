import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jahiz/features/paywall/models/paywall_route_arguments.dart';
import 'package:jahiz/features/paywall/presentation/screens/paywall_screen.dart';
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

  Future<void> _showSessionSummaryDialog(PracticeState state) async {
    final scores = state.scoreByQuestion;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Interview Session Summary'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Average Score',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E5B75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${state.averageScore.toStringAsFixed(1)} / 10',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Per Question Scores',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...List<Widget>.generate(scores.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Question ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${scores[index].toStringAsFixed(1)} / 10',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pop();
              },
              child: const Text('Finish'),
            ),
          ],
        );
      },
    );
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
    final progress = state.questions.isEmpty
        ? 0.0
        : (state.currentIndex + 1) / state.questions.length;

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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFF7F8FF), Color(0xFFEFF3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E3FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E5BFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Question ${state.currentIndex + 1}/${state.questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Interview Prompt',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF5B6275),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.currentQuestion,
              style: const TextStyle(
                fontSize: 18,
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

    final normalized = (evaluation.score / 10).clamp(0.0, 1.0);
    final gradeLabel = evaluation.score >= 8
        ? 'Strong'
        : evaluation.score >= 6
        ? 'Good'
        : 'Needs Work';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E2FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AI Review',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${evaluation.score.toStringAsFixed(1)} / 10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 10,
              backgroundColor: const Color(0xFFE6ECFF),
              color: const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Overall: $gradeLabel',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF55607A),
            ),
          ),
          const SizedBox(height: 10),
          _buildExpandableSection(
            title: 'Detailed Feedback',
            icon: Icons.rate_review_rounded,
            body: evaluation.feedback,
            headerColor: const Color(0xFF3E5BA9),
          ),
          const SizedBox(height: 10),
          _buildExpandableSection(
            title: 'Model Answer',
            icon: Icons.auto_awesome_rounded,
            body: evaluation.modelAnswer,
            headerColor: const Color(0xFF087F5B),
            renderAsMarkdown: true,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required String body,
    required Color headerColor,
    bool renderAsMarkdown = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: headerColor,
          collapsedIconColor: headerColor,
          title: Row(
            children: [
              Icon(icon, color: headerColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                ),
              ),
            ],
          ),
          subtitle: Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.3),
          ),
          children: [
            if (renderAsMarkdown)
              MarkdownBody(
                data: body,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: const TextStyle(height: 1.5)),
              )
            else
              Text(body, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(PracticeState state) {
    final isFirst = state.currentIndex == 0;
    final isLast = state.currentIndex >= state.questions.length - 1;
    final hasEvaluation = state.currentEvaluation != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: isFirst ? null : _cubit.previousQuestion,
                      child: const Text('Previous'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isLast ? null : _cubit.nextQuestion,
                      child: const Text('Next'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isSubmitting || hasEvaluation
                    ? null
                    : _cubit.submitCurrentAnswer,
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        hasEvaluation ? 'Answer Submitted' : 'Submit Answer',
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isSessionSubmitted || state.isSessionSubmitting
                    ? null
                    : () async {
                        final success = await _cubit.submitSession();
                        if (!mounted || !success) {
                          return;
                        }
                        await _showSessionSummaryDialog(state);
                      },
                child: state.isSessionSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        state.isSessionSubmitted
                            ? 'Session Submitted'
                            : 'Submit Interview Session',
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Answered ${state.submittedAnswersCount}/${state.questions.length}',
              style: const TextStyle(
                color: Color(0xFF5B6275),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
            previous.currentAnswer != current.currentAnswer ||
            previous.shouldShowPaywall != current.shouldShowPaywall,
        listener: (context, state) async {
          if (state.shouldShowPaywall) {
            final paywallMessage =
                state.paywallMessage ??
                'This feature is available for Premium users only.';
            final paywallFeatureName = state.paywallFeatureName ?? 'Premium';

            _cubit.consumePaywallRequest();
            if (!mounted) {
              return;
            }

            await Navigator.pushReplacementNamed(
              context,
              PaywallScreen.routeName,
              arguments: PaywallRouteArguments(
                featureName: paywallFeatureName,
                message: paywallMessage,
              ),
            );
            return;
          }

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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                              filled: true,
                              fillColor: Colors.white,
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
                          const Text(
                            'Tap Submit in the bottom bar to get AI review.',
                            style: TextStyle(
                              color: Color(0xFF566079),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          _buildEvaluationCard(state),
                        ],
                      ),
                    ),
              bottomNavigationBar: state.hasQuestions
                  ? _buildBottomActionBar(state)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
