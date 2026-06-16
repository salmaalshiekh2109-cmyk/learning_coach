import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/quiz_controller.dart';
import '../services/local_progress_store.dart';
import '../widgets/frosted_card.dart';
import '../widgets/screen_background.dart';

class ParentSummaryScreen extends ConsumerWidget {
  const ParentSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: ref.read(localProgressStoreProvider).loadLatestSummary(),
        builder: (context, snapshot) {
          final persisted = snapshot.data;
          final name = (persisted?['studentName'] as String?)?.trim();
          final subject = (persisted?['subject'] as String?)?.trim();
          final acc = (persisted?['accuracy'] as num?)?.toDouble();
          final mastery = (persisted?['masteryScore'] as num?)?.toDouble();
          final streak = (persisted?['longestStreak'] as num?)?.toInt();
          final next = (persisted?['recommendedTopic'] as String?)?.trim();

          return ScreenBackground(
            child: ListView(
              children: [
                FrostedCard(
                  child: Text(
                    '${name?.isNotEmpty == true ? name : state.studentName} completed ${state.answeredCount} adaptive questions in ${subject?.isNotEmpty == true ? subject : state.selectedSubject}.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                _summaryLine(
                  'Accuracy',
                  '${(((acc ?? state.accuracy) * 100)).toStringAsFixed(0)}%',
                ),
                _summaryLine(
                  'Mastery',
                  '${(((mastery ?? state.masteryScore) * 100)).toStringAsFixed(0)}%',
                ),
                _summaryLine(
                  'Longest streak',
                  '${streak ?? state.longestStreak}',
                ),
                _summaryLine(
                  'Recommended next topic',
                  (next?.isNotEmpty == true ? next : null) ??
                      state.recommendedTopic ??
                      'Mixed review',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Suggested support at home',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Ask your child to explain one solved problem aloud.',
                ),
                const Text('2. Review the recommended topic for 10 minutes.'),
                const Text(
                  '3. Retake a short quiz tomorrow to reinforce learning.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(value),
          ],
        ),
      ),
    );
  }
}
