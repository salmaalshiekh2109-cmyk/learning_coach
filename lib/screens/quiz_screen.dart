import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/quiz_controller.dart';
import '../models/question.dart';
import '../widgets/frosted_card.dart';
import '../widgets/screen_background.dart';
import 'results_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _locked = false;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(int selectedIndex) async {
    if (_locked) {
      return;
    }

    final controller = ref.read(quizControllerProvider.notifier);
    final isCorrect = controller.submitAnswer(selectedIndex);

    setState(() {
      _locked = true;
      _lastCorrect = isCorrect;
    });

    if (!isCorrect) {
      _shakeController
        ..reset()
        ..forward();
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect
              ? 'Correct. Difficulty increased.'
              : 'Not quite. Difficulty adjusted and hint unlocked.',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }

    final state = ref.read(quizControllerProvider);
    if (state.completed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const ResultsScreen()),
      );
      return;
    }

    setState(() {
      _locked = false;
      _lastCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);
    final question = state.currentQuestion;

    // ── AI generation loading ──
    if (state.isGenerating) {
      return Scaffold(
        body: ScreenBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Generating ${state.selectedSubject} questions with AI…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E4C5A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fresh questions are being created just for you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Generation error ──
    if (state.generationError != null) {
      return Scaffold(
        body: ScreenBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Color(0xFFE85D3C),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load questions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E4C5A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.generationError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4F6773),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(quizControllerProvider.notifier)
                        .retryGeneration(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = state.totalQuestions == 0
        ? 0.0
        : state.answeredCount / state.totalQuestions;

    return Scaffold(
      body: ScreenBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF2E4C5A),
                    size: 22,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    '${state.selectedSubject} Adaptive Quiz',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E4C5A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${state.answeredCount + 1} of ${state.totalQuestions}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF47606F)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip('Difficulty: ${state.currentDifficulty.label}'),
                const SizedBox(width: 8),
                _chip('Streak: ${state.currentStreak}'),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final dx = math.sin(_shakeController.value * math.pi * 6) * 6;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: FrostedCard(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  decoration: BoxDecoration(
                    color: _lastCorrect == true
                        ? const Color(0x14A2E3BF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.topic,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF47606F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.prompt,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _locked ? null : () => _submitAnswer(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD8E3EE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F2F8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(question.options[index])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _showHintSheet(context, question),
              icon: const Icon(Icons.help_outline),
              label: const Text('Need a hint?'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _showHintSheet(BuildContext context, Question question) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hint',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(question.hint, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 14),
              const Text(
                'Explanation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                question.explanation,
                style: const TextStyle(fontSize: 15, color: Color(0xFF3B4E59)),
              ),
            ],
          ),
        );
      },
    );
  }
}
