import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/quiz_controller.dart';
import '../services/local_progress_store.dart';
import '../widgets/frosted_card.dart';
import '../widgets/line_trend_chart.dart';
import '../widgets/screen_background.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final masteryList = state.masteryByTopic.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final weakTopics = masteryList.take(2).map((entry) => entry.key).toList();
    final strongTopics = masteryList.reversed
        .take(2)
        .map((entry) => entry.key)
        .toList();
    final recent = state.history.reversed.take(4).toList();

    return Scaffold(
      body: ScreenBackground(
        child: ListView(
          children: [
            FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mastery Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<List<double>>(
                    future: ref
                        .read(localProgressStoreProvider)
                        .loadMasteryTrend(),
                    builder: (context, snapshot) {
                      final points =
                          snapshot.data ?? <double>[state.masteryScore];
                      return LineTrendChart(points: points);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    label: 'Accuracy',
                    value: '${(state.accuracy * 100).toStringAsFixed(0)}%',
                    tint: const Color(0xFFE1F6F8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStat(
                    label: 'Mastery',
                    value: '${(state.masteryScore * 100).toStringAsFixed(0)}%',
                    tint: const Color(0xFFFFF1DF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStat(
                    label: 'Streak',
                    value: '${state.currentStreak}',
                    tint: const Color(0xFFFFE8E6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _metricTile(
              title: 'Time spent learning',
              value: '${state.estimatedMinutesSpent} min',
              subtitle: 'Session-based estimate',
              icon: Icons.schedule,
            ),
            _metricTile(
              title: 'Next lesson suggestion',
              value: state.recommendedTopic ?? 'Mixed review',
              subtitle: 'Picked from weakest mastery signal',
              icon: Icons.auto_awesome,
            ),
            _metricTile(
              title: 'Current streak',
              value: '${state.currentStreak}',
              subtitle: 'Best streak: ${state.longestStreak}',
              icon: Icons.local_fire_department_outlined,
            ),
            const SizedBox(height: 10),
            FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Topic Focus',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Weak topics',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final topic in weakTopics) Chip(label: Text(topic)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Strong topics',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final topic in strongTopics)
                        Chip(label: Text(topic)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    const Text(
                      'No activity yet. Complete one quiz session to populate this feed.',
                    )
                  else
                    for (final record in recent)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          record.isCorrect
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: record.isCorrect
                              ? const Color(0xFF1E9B5C)
                              : const Color(0xFFD84D3F),
                        ),
                        title: Text(record.question.topic),
                        subtitle: Text(record.question.prompt),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF425868)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
