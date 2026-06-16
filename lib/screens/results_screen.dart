import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
import '../models/user_role.dart';
import '../services/local_progress_store.dart';
import '../widgets/frosted_card.dart';
import '../widgets/screen_background.dart';
import 'parent_shell_screen.dart';
import 'skill_progress_screen.dart';
import 'student_shell_screen.dart';
import 'teacher_shell_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_saved) {
      return;
    }

    final state = ref.read(quizControllerProvider);
    if (!state.completed) {
      return;
    }

    _saved = true;
    ref.read(localProgressStoreProvider).saveCompletedSession(state);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final masteryPercent = (state.masteryScore * 100).toStringAsFixed(0);

    return Scaffold(
      body: ScreenBackground(
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient:  LinearGradient(
                  colors: [Color(0xFF0B7B83), Color(0xFF3AA6AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow:  [
                  BoxShadow(
                    color: Color(0x220A7B83),
                    blurRadius: 26,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Great work, ${state.studentName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Mastery Score: $masteryPercent%',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Accuracy: ${(state.accuracy * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Longest streak: ${state.longestStreak}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FrostedCard(
              padding: const EdgeInsets.all(14),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome, size: 28),
                title: const Text(
                  'Next recommended topic',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    state.recommendedTopic ?? 'Keep practicing mixed topics',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                final role = auth?.role ?? UserRole.student;
                Widget target;
                if (role == UserRole.parent) {
                  target = const ParentShellScreen();
                } else if (role == UserRole.teacher) {
                  target = const TeacherShellScreen();
                } else {
                  target = const StudentShellScreen();
                }

                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => target),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Open My Workspace'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SkillProgressScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.school_outlined),
              label: const Text('View Skill Progress'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const TeacherShellScreen(),
                  ),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.groups_2_outlined),
              label: const Text('Teacher Analytics'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const ParentShellScreen(),
                  ),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.family_restroom_outlined),
              label: const Text('Parent Workspace'),
            ),
          ],
        ),
      ),
    );
  }
}
