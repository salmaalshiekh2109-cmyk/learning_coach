import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../models/user_role.dart';
import '../widgets/frosted_card.dart';
import 'parent_shell_screen.dart';
import 'student_shell_screen.dart';
import 'teacher_shell_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDBF5F6), Color(0xFFF7F9FF), Color(0xFFFFF4E8)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child:  Text(
                          'Adaptive learning, redesigned',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF255464),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Personalized\nLearning Coach',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                       Text(
                        'A smart study companion that adapts in real time to each answer you give.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2E4C5A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _FeatureChip(
                            icon: Icons.bolt_outlined,
                            label: 'Live adaptation',
                          ),
                          _FeatureChip(
                            icon: Icons.lightbulb_outline,
                            label: 'Smart hints',
                          ),
                          _FeatureChip(
                            icon: Icons.insights_outlined,
                            label: 'Progress analytics',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FrostedCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SegmentedButton<UserRole>(
                              segments: const [
                                ButtonSegment(
                                  value: UserRole.student,
                                  label: Text('Student'),
                                  icon: Icon(Icons.school_outlined),
                                ),
                                ButtonSegment(
                                  value: UserRole.parent,
                                  label: Text('Parent'),
                                  icon: Icon(Icons.family_restroom_outlined),
                                ),
                                ButtonSegment(
                                  value: UserRole.teacher,
                                  label: Text('Teacher'),
                                  icon: Icon(Icons.groups_2_outlined),
                                ),
                              ],
                              selected: <UserRole>{_selectedRole},
                              onSelectionChanged: (roles) {
                                setState(() {
                                  _selectedRole = roles.first;
                                });
                              },
                              showSelectedIcon: false,
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: '${_selectedRole.label} Name',
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  final name = _nameController.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter your name.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  ref
                                      .read(authControllerProvider.notifier)
                                      .login(name: name, role: _selectedRole);

                                  if (_selectedRole == UserRole.student) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const StudentShellScreen(),
                                      ),
                                    );
                                    return;
                                  }

                                  if (_selectedRole == UserRole.parent) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ParentShellScreen(),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const TeacherShellScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  _selectedRole == UserRole.student
                                      ? 'Start Learning'
                                      : 'Continue to ${_selectedRole.label} View',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Expanded(
                            child: _QuickMetric(
                              label: 'Learners',
                              value: '1.2k',
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _QuickMetric(
                              label: 'Avg score lift',
                              value: '+22%',
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _QuickMetric(
                              label: 'Daily streaks',
                              value: '340',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF275766)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _QuickMetric extends StatelessWidget {
  const _QuickMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF4F6773)),
          ),
        ],
      ),
    );
  }
}
