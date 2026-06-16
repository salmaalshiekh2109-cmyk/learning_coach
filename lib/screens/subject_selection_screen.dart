import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
import '../models/user_role.dart';
import '../widgets/frosted_card.dart';
import '../widgets/screen_background.dart';
import 'quiz_screen.dart';

class SubjectSelectionScreen extends ConsumerWidget {
  const SubjectSelectionScreen({super.key, required this.studentName});

  final String studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth == null || auth.role != UserRole.student) {
      return Scaffold(
        body: SafeArea(
          child: const Center(
            child: Text('Student access is required for quizzes.'),
          ),
        ),
      );
    }

    final subjects = ref
        .read(quizControllerProvider.notifier)
        .availableSubjects();

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
                  'Choose Subject',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E4C5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Hey $studentName, pick a lesson to begin your adaptive session.',
              style: const TextStyle(fontSize: 15, color: Color(0xFF466170)),
            ),
            const SizedBox(height: 10),
            FrostedCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: const [
                  Expanded(
                    child: _PlanStat(label: 'Daily Goal', value: '20 min'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _PlanStat(label: 'Focus', value: 'Adaptive Quiz'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _PlanStat(label: 'Reward', value: 'New Badge'),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < subjects.length; index++)
              FrostedCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    final subject = subjects[index];
                    ref
                        .read(quizControllerProvider.notifier)
                        .startQuizLoading(
                          studentName: studentName,
                          subject: subject,
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const QuizScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: index.isEven
                              ? const Color(0xFFDDF5F7)
                              : const Color(0xFFFFEDD8),
                        ),
                        child: Icon(
                          index.isEven
                              ? Icons.calculate_outlined
                              : Icons.science_outlined,
                          color: const Color(0xFF245566),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjects[index],
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Adaptive quiz, hints, mastery updates',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF48606D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: const [
                                _MetaTag('8 questions'),
                                SizedBox(width: 6),
                                _MetaTag('Real-time difficulty'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  const _PlanStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF4D6573)),
        ),
      ],
    );
  }
}
