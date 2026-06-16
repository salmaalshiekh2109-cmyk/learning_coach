import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/frosted_card.dart';
import '../widgets/line_trend_chart.dart';
import '../widgets/screen_background.dart';
import 'onboarding_screen.dart';

class TeacherShellScreen extends ConsumerStatefulWidget {
  const TeacherShellScreen({super.key});

  @override
  ConsumerState<TeacherShellScreen> createState() => _TeacherShellScreenState();
}

class _TeacherShellScreenState extends ConsumerState<TeacherShellScreen> {
  int _index = 0;
  final _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  Widget build(BuildContext context) {
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
                rootBuilder: () => const _TeacherAnalyticsTab(),
              ),
              _buildTabNavigator(
                tabIndex: 1,
                currentIndex: _index,
                rootBuilder: () => const _TeacherClassesTab(),
              ),
              _buildTabNavigator(
                tabIndex: 2,
                currentIndex: _index,
                rootBuilder: () => const _TeacherAssignmentsTab(),
              ),
              _buildTabNavigator(
                tabIndex: 3,
                currentIndex: _index,
                rootBuilder: () => const _TeacherAlertsTab(),
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
              icon: Icon(Icons.insights_outlined),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              label: 'Alerts',
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

class _TeacherAnalyticsTab extends ConsumerWidget {
  const _TeacherAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final avgPct = (state.masteryScore * 100).toStringAsFixed(0);
    final strugglingTopics = state.masteryByTopic.entries
        .where((e) => e.value < 0.55)
        .map((e) => e.key)
        .toList();
    final trend = state.masteryTrend;

    return ScreenBackground(
      child: ListView(
        children: [
          // ── Hero banner (orange) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFD05E1A), Color(0xFFF09040)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3AD05E1A),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Class Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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
                const SizedBox(height: 2),
                const Text(
                  'Live adaptive data from your students.',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _kpiPill('$avgPct%', 'Mastery avg'),
                    const SizedBox(width: 8),
                    _kpiPill('${strugglingTopics.length}', 'Gap topics'),
                    const SizedBox(width: 8),
                    _kpiPill('${trend.length}', 'Sessions'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Trend chart ──
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0DE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights,
                        color: Color(0xFFD05E1A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Weekly Mastery Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (trend.length < 2)
                  const SizedBox(
                    height: 110,
                    child: Center(
                      child: Text(
                        'Complete 2+ quiz sessions to see the trend.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4F6773),
                        ),
                      ),
                    ),
                  )
                else
                  LineTrendChart(points: trend, color: const Color(0xFFD05E1A)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Gap topics ──
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE85D3C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Knowledge Gaps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (strugglingTopics.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'No struggling topics yet — excellent progress!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF27AE68),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                for (final topic in strugglingTopics) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE85D3C),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          topic,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8E4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Needs focus',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE85D3C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiPill(String value, String label) {
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
}

// ─────────────────── CLASSES ───────────────────

class _TeacherClassesTab extends ConsumerWidget {
  const _TeacherClassesTab();

  static const _colors = [
    Color(0xFF0A7B83),
    Color(0xFFD05E1A),
    Color(0xFF27AE68),
    Color(0xFF5B67CA),
  ];
  static const _icons = [
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.menu_book_outlined,
    Icons.palette_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(quizControllerProvider);
    final notifier = ref.read(quizControllerProvider.notifier);
    final subjects = notifier.availableSubjects();
    final masteryMap = notifier.subjectMastery();

    return ScreenBackground(
      child: ListView(
        children: [
          FrostedCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subjects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Live mastery data from the student\'s quiz sessions.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < subjects.length; i++) ...[
            FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length].withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _icons[i % _icons.length],
                          color: _colors[i % _colors.length],
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjects[i],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            _badge(
                              (masteryMap[subjects[i]] ?? 0) >= 0.7
                                  ? 'On track'
                                  : (masteryMap[subjects[i]] ?? 0) >= 0.45
                                  ? 'Developing'
                                  : 'Needs focus',
                              (masteryMap[subjects[i]] ?? 0) >= 0.7
                                  ? const Color(0xFF27AE68)
                                  : (masteryMap[subjects[i]] ?? 0) >= 0.45
                                  ? const Color(0xFFF69B45)
                                  : const Color(0xFFE85D3C),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${((masteryMap[subjects[i]] ?? 0) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _colors[i % _colors.length],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: masteryMap[subjects[i]] ?? 0,
                      minHeight: 7,
                      backgroundColor: _colors[i % _colors.length].withValues(
                        alpha: 0.15,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _colors[i % _colors.length],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────── ASSIGNMENTS ───────────────────

class _TeacherAssignmentsTab extends ConsumerWidget {
  const _TeacherAssignmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);

    final weakTopics =
        state.masteryByTopic.entries.where((e) => e.value < 0.65).toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    final strongTopics = state.masteryByTopic.entries
        .where((e) => e.value >= 0.65)
        .toList();

    final items = [
      ...weakTopics
          .take(3)
          .map(
            (e) => (
              title: '${e.key} Practice Quiz',
              details:
                  '${(e.value * 100).toStringAsFixed(0)}% mastery — needs work',
              icon: Icons.assignment_outlined,
              color: e.value < 0.4
                  ? const Color(0xFFE85D3C)
                  : const Color(0xFFF69B45),
              urgency: e.value < 0.4 ? 'High priority' : 'This week',
              urgencyColor: e.value < 0.4
                  ? const Color(0xFFE85D3C)
                  : const Color(0xFFF69B45),
            ),
          ),
      ...strongTopics
          .take(2)
          .map(
            (e) => (
              title: '${e.key} Challenge',
              details:
                  '${(e.value * 100).toStringAsFixed(0)}% mastery — ready to advance',
              icon: Icons.stars_outlined,
              color: const Color(0xFF27AE68),
              urgency: 'Optional',
              urgencyColor: const Color(0xFF27AE68),
            ),
          ),
    ];

    return ScreenBackground(
      child: ListView(
        children: [
          FrostedCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Assignments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Practice tasks driven by the student\'s current mastery data.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const FrostedCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Complete a quiz first — assignments will appear based on results.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
                ),
              ),
            ),
          for (final item in items) ...[
            FrostedCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.details,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4F6773),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: item.urgencyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.urgency,
                      style: TextStyle(
                        color: item.urgencyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ─────────────────── ALERTS ───────────────────

class _TeacherAlertsTab extends ConsumerWidget {
  const _TeacherAlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);

    final alerts =
        <({String text, String label, Color color, IconData icon})>[];

    for (final entry in state.masteryByTopic.entries) {
      if (entry.value < 0.4) {
        alerts.add((
          text:
              '${entry.key} mastery is critically low '
              '(${(entry.value * 100).toStringAsFixed(0)}%). Immediate review recommended.',
          label: 'Critical',
          color: const Color(0xFFE85D3C),
          icon: Icons.error_outline,
        ));
      }
    }
    for (final entry in state.masteryByTopic.entries) {
      if (entry.value >= 0.4 && entry.value < 0.6) {
        alerts.add((
          text:
              '${entry.key} needs reinforcement '
              '(${(entry.value * 100).toStringAsFixed(0)}% mastery).',
          label: 'Warning',
          color: const Color(0xFFF69B45),
          icon: Icons.warning_amber_rounded,
        ));
      }
    }
    for (final entry in state.masteryByTopic.entries) {
      if (entry.value >= 0.8) {
        alerts.add((
          text:
              '${entry.key} mastery is excellent '
              '(${(entry.value * 100).toStringAsFixed(0)}%). Consider harder challenges.',
          label: 'Excellent',
          color: const Color(0xFF27AE68),
          icon: Icons.trending_up,
        ));
      }
    }
    if (state.totalXp >= 50) {
      alerts.add((
        text: 'Student has earned ${state.totalXp} XP — strong engagement!',
        label: 'Progress',
        color: const Color(0xFF5B67CA),
        icon: Icons.stars_outlined,
      ));
    }
    if (state.answeredCount == 0) {
      alerts.add((
        text:
            'No quiz activity yet. Encourage the student to start their first session.',
        label: 'Info',
        color: const Color(0xFF0A7B83),
        icon: Icons.info_outline,
      ));
    }

    return ScreenBackground(
      child: ListView(
        children: [
          FrostedCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts & Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Real-time flags from the adaptive learning system.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final alert in alerts) ...[
            FrostedCard(
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: alert.color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: alert.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                alert.icon,
                                color: alert.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: alert.color.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      alert.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: alert.color,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    alert.text,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: Color(0xFF2E4C5A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
