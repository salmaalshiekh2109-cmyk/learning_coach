import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/quiz_controller.dart';
import '../services/local_progress_store.dart';
import '../widgets/frosted_card.dart';
import '../widgets/line_trend_chart.dart';
import '../widgets/screen_background.dart';
import '../widgets/skill_tracker_card.dart';

class SkillProgressScreen extends ConsumerWidget {
  const SkillProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);

    return Scaffold(
      body: ScreenBackground(
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: Color(0xFF2E4C5A),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const Text(
                  'Skill Progress',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E4C5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall mastery ${(state.masteryScore * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<double>>(
                    future: ref
                        .read(localProgressStoreProvider)
                        .loadMasteryTrend(),
                    builder: (context, snapshot) {
                      final data =
                          snapshot.data ?? <double>[state.masteryScore];
                      return LineTrendChart(points: data);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final entry in state.masteryByTopic.entries)
              SkillTrackerCard(
                topic: entry.key,
                mastery: entry.value,
                accuracy: state.accuracy,
              ),
          ],
        ),
      ),
    );
  }
}
