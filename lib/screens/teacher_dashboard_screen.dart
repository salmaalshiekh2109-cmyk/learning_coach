import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/quiz_controller.dart';
import '../services/analytics_api_service.dart';
import '../widgets/frosted_card.dart';
import '../widgets/line_trend_chart.dart';
import '../widgets/screen_background.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);

    final sorted = state.masteryByTopic.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Scaffold(
      body: FutureBuilder<TeacherAnalyticsSnapshot>(
        future: ref
            .read(analyticsApiServiceProvider)
            .fetchClassSnapshot(
              subject: state.selectedSubject.isEmpty
                  ? 'General'
                  : state.selectedSubject,
            ),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final commonMistakes = data?.commonMistakes ?? const <String>[];
          final strugglingTopics =
              data?.strugglingTopics ??
              sorted.take(2).map((entry) => entry.key).toList();
          final weeklyMastery =
              data?.weeklyMastery ?? <double>[state.masteryScore];

          return ScreenBackground(
            child: ListView(
              children: [
                FrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Class average ${(100 * (data?.classAverage ?? 0.7)).toStringAsFixed(0)}%',
                      ),
                      const SizedBox(height: 8),
                      LineTrendChart(
                        points: weeklyMastery,
                        color: const Color(0xFFF69B45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.rule_folder_outlined),
                    title: const Text('Common mistakes'),
                    subtitle: Text(
                      commonMistakes.isEmpty
                          ? 'No major errors this round.'
                          : commonMistakes.join(' | '),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.gpp_bad_outlined),
                    title: const Text('Topic gaps'),
                    subtitle: Text(strugglingTopics.join(', ')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
