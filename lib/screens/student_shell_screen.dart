import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/frosted_card.dart';
import '../widgets/line_trend_chart.dart';
import '../widgets/screen_background.dart';
import 'onboarding_screen.dart';
import 'quiz_screen.dart';
import 'subject_selection_screen.dart';

class StudentShellScreen extends ConsumerStatefulWidget {
  const StudentShellScreen({super.key});

  @override
  ConsumerState<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends ConsumerState<StudentShellScreen> {
  int _index = 0;
  final _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final name = (auth?.name.isNotEmpty ?? false) ? auth!.name : 'Student';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final currentNavigator = _navigatorKeys[_index].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              _buildTabNavigator(
                tabIndex: 0,
                currentIndex: _index,
                rootBuilder: () => _StudentHomeTab(name: name),
              ),
              _buildTabNavigator(
                tabIndex: 1,
                currentIndex: _index,
                rootBuilder: () => const _StudentLearnTab(),
              ),
              _buildTabNavigator(
                tabIndex: 2,
                currentIndex: _index,
                rootBuilder: () => _StudentTestsTab(name: name),
              ),
              _buildTabNavigator(
                tabIndex: 3,
                currentIndex: _index,
                rootBuilder: () => const _StudentProgressTab(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) {
            if (value == _index) {
              _navigatorKeys[value].currentState?.popUntil(
                (route) => route.isFirst,
              );
              return;
            }
            setState(() {
              _index = value;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.lightbulb_outline),
              label: 'Learn',
            ),
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              label: 'Tests',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigator({
    required int tabIndex,
    required int currentIndex,
    required Widget Function() rootBuilder,
  }) {
    return Offstage(
      offstage: currentIndex != tabIndex,
      child: Navigator(
        key: _navigatorKeys[tabIndex],
        onGenerateRoute: (_) {
          return MaterialPageRoute<void>(builder: (_) => rootBuilder());
        },
      ),
    );
  }
}

class _StudentHomeTab extends ConsumerWidget {
  const _StudentHomeTab({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final mastery = (state.masteryScore * 100).toStringAsFixed(0);
    final accuracy = (state.accuracy * 100).toStringAsFixed(0);

    return ScreenBackground(
      child: ListView(
        children: [
          // â”€â”€ Hero banner â”€â”€
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF0A7B83), Color(0xFF16AABB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3A0A7B83),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $name!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Ready to level up today?',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Color(0xFFFFD166),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${state.currentStreak}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        ref.read(authControllerProvider.notifier).logout();
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const OnboardingScreen(),
                          ),
                          (_) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _heroPill('$mastery%', 'Mastery'),
                    const SizedBox(width: 8),
                    _heroPill('$accuracy%', 'Accuracy'),
                    const SizedBox(width: 8),
                    _heroPill('${state.answeredCount}', 'Answered'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // â”€â”€ Recommended topic â”€â”€
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0D8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFF69B45),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Recommended Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  state.recommendedTopic ?? 'Mixed Adaptive Review',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A7B83),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Questions adapt in real-time to your answers.',
                  style: TextStyle(color: Color(0xFF4F6773), fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SubjectSelectionScreen(studentName: name),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Quiz'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // â”€â”€ Trend chart â”€â”€
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F9FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights,
                        color: Color(0xFF0A7B83),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Mastery Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        '7 days',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0A7B83),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final trend = state.masteryTrend;
                    if (trend.length < 2) {
                      return const SizedBox(
                        height: 110,
                        child: Center(
                          child: Text(
                            'Complete 2 or more quizzes to see your trend.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4F6773),
                            ),
                          ),
                        ),
                      );
                    }
                    return LineTrendChart(points: trend);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // â”€â”€ Stats row â”€â”€
          Row(
            children: [
              _statTile(
                'Topics\ntouched',
                '${state.masteryByTopic.length}',
                Icons.category_outlined,
                const Color(0xFF5B67CA),
              ),
              const SizedBox(width: 10),
              _statTile(
                'Best\nstreak',
                '${state.longestStreak}',
                Icons.emoji_events_outlined,
                const Color(0xFFF69B45),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xBBFFFFFF), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4F6773),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== LEARN TAB =====

/// Static per-topic study notes shown in the Learn tab.
/// These are intentionally separate from AI-generated quiz questions so the
/// tab renders instantly without a network call.
const _learnTopics =
    <
      ({
        String subject,
        String topic,
        String summary,
        List<String> keyFacts,
        IconData icon,
        Color color,
      })
    >[
      (
        subject: 'Math',
        topic: 'Arithmetic',
        summary:
            'Arithmetic covers the basic operations — addition, subtraction, '
            'multiplication, and division — that underpin all of mathematics.',
        keyFacts: [
          'Adding two numbers gives their sum',
          'Subtraction finds the difference between two values',
          'Multiplication is repeated addition: 4 × 3 = 4 + 4 + 4 = 12',
          'Division splits a value into equal parts: 12 ÷ 3 = 4',
          'BODMAS/PEMDAS defines the order of operations',
        ],
        icon: Icons.calculate_outlined,
        color: Color(0xFF0A7B83),
      ),
      (
        subject: 'Math',
        topic: 'Algebra',
        summary:
            'Algebra uses letters (variables) to represent unknown values, '
            'allowing general rules and equations to be written and solved.',
        keyFacts: [
          'A variable (e.g. x) stands for an unknown number',
          'An equation states that two expressions are equal: 2x + 3 = 11',
          'Apply the same operation to both sides to keep the balance',
          'Collecting like terms simplifies expressions: 3x + 2x = 5x',
        ],
        icon: Icons.calculate_outlined,
        color: Color(0xFF5B67CA),
      ),
      (
        subject: 'Math',
        topic: 'Geometry',
        summary:
            'Geometry explores shapes, sizes, and the properties of space, '
            'from flat 2-D figures to solid 3-D objects.',
        keyFacts: [
          'Perimeter is the total distance around a shape',
          'Area is the space inside a 2-D shape',
          'A triangle\'s interior angles always add up to 180°',
          'Area of a rectangle = length × width',
          'The circumference of a circle = 2πr',
        ],
        icon: Icons.architecture_outlined,
        color: Color(0xFF27AE68),
      ),
      (
        subject: 'Math',
        topic: 'Fractions',
        summary:
            'A fraction represents a part of a whole. '
            'Understanding fractions is key to working with ratios, decimals, and percentages.',
        keyFacts: [
          'The numerator (top) shows how many parts you have',
          'The denominator (bottom) shows how many equal parts in the whole',
          'Equivalent fractions: 1/2 = 2/4 = 3/6',
          'To add fractions, first find a common denominator',
          'A mixed number combines a whole number and a fraction: 1½',
        ],
        icon: Icons.pie_chart_outline,
        color: Color(0xFFF69B45),
      ),
      (
        subject: 'Science',
        topic: 'Biology',
        summary:
            'Biology is the study of living organisms — from microscopic cells '
            'to entire ecosystems.',
        keyFacts: [
          'All living things are made of cells',
          'Photosynthesis: plants use sunlight, water, and CO₂ to make food',
          'DNA carries genetic instructions for every organism',
          'Ecosystems include producers, consumers, and decomposers',
        ],
        icon: Icons.science_outlined,
        color: Color(0xFF0A7B83),
      ),
      (
        subject: 'Science',
        topic: 'Chemistry',
        summary:
            'Chemistry investigates the composition, properties, and '
            'transformations of matter.',
        keyFacts: [
          'All matter is made of atoms',
          'Elements are pure substances with one type of atom (see periodic table)',
          'Compounds form when two or more elements chemically bond: H₂O',
          'Acids have a pH below 7; bases above 7; neutral = 7',
        ],
        icon: Icons.biotech_outlined,
        color: Color(0xFF5B67CA),
      ),
      (
        subject: 'Science',
        topic: 'Physics',
        summary:
            'Physics explains how forces, energy, and matter interact in the universe.',
        keyFacts: [
          'Newton\'s 1st Law: objects stay at rest or in motion unless a force acts',
          'Newton\'s 2nd Law: Force = Mass × Acceleration (F = ma)',
          'Newton\'s 3rd Law: every action has an equal and opposite reaction',
          'Energy cannot be created or destroyed — only converted',
        ],
        icon: Icons.bolt_outlined,
        color: Color(0xFF27AE68),
      ),
      (
        subject: 'Science',
        topic: 'Earth Science',
        summary:
            'Earth Science covers the structure of our planet, its weather, '
            'and the geological forces that shape it.',
        keyFacts: [
          'Earth\'s layers: crust, mantle, outer core, inner core',
          'Tectonic plates move and cause earthquakes and volcanic eruptions',
          'The water cycle: evaporation → condensation → precipitation',
          'Climate is the long-term average weather over 30+ years',
        ],
        icon: Icons.public_outlined,
        color: Color(0xFFF69B45),
      ),
    ];

class _StudentLearnTab extends StatelessWidget {
  const _StudentLearnTab();

  @override
  Widget build(BuildContext context) {
    const lessons = _learnTopics;

    return ScreenBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Hero banner
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A8F5A), Color(0xFF3DBE7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x331A8F5A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Study & Learn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Read the concepts, memorise the key facts, then head to Tests to check yourself.',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Study tip
          FrostedCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D0),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.tips_and_updates_outlined,
                    color: Color(0xFFF0A500),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Tip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F6773),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Read each key fact out loud. Saying information aloud improves memory retention significantly.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Lesson Topics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E4C5A),
              ),
            ),
          ),
          for (final lesson in lessons) ...[
            _LessonCard(
              subject: lesson.subject,
              topic: lesson.topic,
              summary: lesson.summary,
              keyFacts: lesson.keyFacts,
              icon: lesson.icon,
              color: lesson.color,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ===== LESSON CARD =====

class _LessonCard extends StatefulWidget {
  const _LessonCard({
    required this.subject,
    required this.topic,
    this.summary,
    required this.keyFacts,
    required this.icon,
    required this.color,
  });

  final String subject;
  final String topic;
  final String? summary;
  final List<String> keyFacts;
  final IconData icon;
  final Color color;

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expand;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expand = CurveTween(curve: Curves.easeInOut).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return FrostedCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header row (always visible)
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(widget.icon, color: c, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: c,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.topic,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4F6773),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 320),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: c),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedBuilder(
            animation: _expand,
            builder: (context, child) {
              return ClipRect(
                child: Align(heightFactor: _expand.value, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  if (widget.summary != null) ...[
                    Text(
                      widget.summary!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF4F6773),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Key Facts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final fact in widget.keyFacts) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fact,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Ready? Tap the Tests tab to test yourself!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== SUBJECT CARD =====

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.color,
    required this.icon,
    required this.mastery,
    required this.onTap,
  });

  final String subject;
  final Color color;
  final IconData icon;
  final double mastery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FrostedCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: mastery,
                            minHeight: 5,
                            backgroundColor: color.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(mastery * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== TESTS TAB =====

class _StudentTestsTab extends ConsumerWidget {
  const _StudentTestsTab({required this.name});

  final String name;

  static const _subjectColors = <Color>[
    Color(0xFF0A7B83),
    Color(0xFFF69B45),
    Color(0xFF5B67CA),
    Color(0xFF27AE68),
    Color(0xFFE85D3C),
    Color(0xFF7C5CC8),
  ];

  static const _subjectIcons = <IconData>[
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.public_outlined,
    Icons.menu_book_outlined,
    Icons.history_edu_outlined,
    Icons.palette_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref
        .read(quizControllerProvider.notifier)
        .availableSubjects();
    // Watch state so the tab rebuilds when mastery changes.
    ref.watch(quizControllerProvider);
    final subjectMastery = ref
        .read(quizControllerProvider.notifier)
        .subjectMastery();

    return ScreenBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Hero banner
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF3A50CC), Color(0xFF6A7DE8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x353A50CC),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.quiz_outlined, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Tests & Quizzes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Adaptive assessments that adjust in real-time to your answers.',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // How it works card
          FrostedCard(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How adaptive testing works',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _howRow(
                  Icons.trending_up_rounded,
                  'Correct answer - next question gets harder',
                  const Color(0xFF27AE68),
                ),
                const SizedBox(height: 6),
                _howRow(
                  Icons.trending_down_rounded,
                  'Wrong answer - easier question + hint unlocked',
                  const Color(0xFFE85D3C),
                ),
                const SizedBox(height: 6),
                _howRow(
                  Icons.local_fire_department_outlined,
                  'Build a streak - mastery score rises faster',
                  const Color(0xFFF69B45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Choose a Subject',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E4C5A),
              ),
            ),
          ),
          for (var i = 0; i < subjects.length; i++) ...[
            _SubjectCard(
              subject: subjects[i],
              color: _subjectColors[i % _subjectColors.length],
              icon: _subjectIcons[i % _subjectIcons.length],
              mastery: subjectMastery[subjects[i]] ?? 0.0,
              onTap: () {
                ref
                    .read(quizControllerProvider.notifier)
                    .startQuizLoading(studentName: name, subject: subjects[i]);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const QuizScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _howRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2E4C5A)),
          ),
        ),
      ],
    );
  }
}

// ===== PROGRESS TAB =====

class _StudentProgressTab extends ConsumerWidget {
  const _StudentProgressTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final mastery = (state.masteryScore * 100).toStringAsFixed(0);
    final accuracy = (state.accuracy * 100).toStringAsFixed(0);

    final goals = [
      (
        title: 'Answer 5 questions correctly',
        xp: 20,
        icon: Icons.psychology_outlined,
        color: const Color(0xFF5B67CA),
        completed: state.goalsAwardedToday.contains('correct_5'),
      ),
      (
        title: 'Build a 3-answer streak',
        xp: 20,
        icon: Icons.local_fire_department_outlined,
        color: const Color(0xFFF69B45),
        completed: state.goalsAwardedToday.contains('streak_3'),
      ),
      (
        title: 'Explore 3 different topics',
        xp: 30,
        icon: Icons.trending_up,
        color: const Color(0xFF27AE68),
        completed: state.goalsAwardedToday.contains('topics_3'),
      ),
      (
        title: 'Finish a full quiz session',
        xp: 25,
        icon: Icons.flag_outlined,
        color: const Color(0xFF0A7B83),
        completed: state.goalsAwardedToday.contains('finish_quiz'),
      ),
    ];

    return ScreenBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Hero banner
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF5B3FAA), Color(0xFF8B68D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x355B3FAA),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'My Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _progressPill('$mastery%', 'Mastery'),
                    const SizedBox(width: 8),
                    _progressPill('$accuracy%', 'Accuracy'),
                    const SizedBox(width: 8),
                    _progressPill('${state.totalXp}', 'Total XP'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Streak card
          FrostedCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0D0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFF69B45),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.currentStreak} answer streak',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Best: ${state.longestStreak}  ·  Answered: ${state.answeredCount}  ·  Topics: ${state.masteryByTopic.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4F6773),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Mastery by topic
          if (state.masteryByTopic.isNotEmpty) ...[
            FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mastery by Topic',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (final entry in state.masteryByTopic.entries) ...[
                    _masteryRow(entry.key, entry.value),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Daily Goals
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3B5C), Color(0xFF2A5580)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Goals",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete goals to earn XP and improve your mastery rating.',
                  style: TextStyle(color: Color(0xBBFFFFFF), fontSize: 12),
                ),
                const SizedBox(height: 12),
                for (final goal in goals)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: goal.completed
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: goal.completed
                            ? Colors.white.withValues(alpha: 0.35)
                            : goal.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: goal.completed
                                ? Colors.white.withValues(alpha: 0.18)
                                : goal.color.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            goal.completed
                                ? Icons.check_circle_rounded
                                : goal.icon,
                            color: goal.completed ? Colors.white : goal.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: TextStyle(
                              color: goal.completed
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              decoration: goal.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: Colors.white.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: goal.completed
                                ? Colors.white.withValues(alpha: 0.2)
                                : goal.color.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${goal.xp} XP',
                            style: TextStyle(
                              color: goal.completed ? Colors.white : goal.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xBBFFFFFF), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _masteryRow(String topic, double value) {
    const colors = [
      Color(0xFF0A7B83),
      Color(0xFF5B67CA),
      Color(0xFF27AE68),
      Color(0xFFF69B45),
      Color(0xFFE85D3C),
    ];
    final color = colors[topic.codeUnits.first % colors.length];
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            topic,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
