import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/frosted_card.dart';
import '../widgets/line_trend_chart.dart';
import '../widgets/screen_background.dart';
import 'onboarding_screen.dart';

class ParentShellScreen extends ConsumerStatefulWidget {
  const ParentShellScreen({super.key});

  @override
  ConsumerState<ParentShellScreen> createState() => _ParentShellScreenState();
}

class _ParentShellScreenState extends ConsumerState<ParentShellScreen> {
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
                rootBuilder: () => const _ParentOverviewTab(),
              ),
              _buildTabNavigator(
                tabIndex: 1,
                currentIndex: _index,
                rootBuilder: () => const _ParentInsightsTab(),
              ),
              _buildTabNavigator(
                tabIndex: 2,
                currentIndex: _index,
                rootBuilder: () => const _ParentPlannerTab(),
              ),
              _buildTabNavigator(
                tabIndex: 3,
                currentIndex: _index,
                rootBuilder: () => const _ParentMessagesTab(),
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
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              label: 'Planner',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Messages',
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

class _ParentOverviewTab extends ConsumerWidget {
  const _ParentOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final parentName = (auth?.name.isNotEmpty ?? false) ? auth!.name : 'Parent';
    final weakestTopic = state.masteryByTopic.isEmpty
        ? null
        : state.masteryByTopic.entries
              .reduce((a, b) => a.value < b.value ? a : b)
              .key;

    return ScreenBackground(
      child: ListView(
        children: [
          // ── Hero banner (purple) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF6D4ACC), Color(0xFF9370DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3A6D4ACC),
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
                        parentName.isNotEmpty
                            ? parentName[0].toUpperCase()
                            : 'P',
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
                            'Hello, $parentName!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            "Here's your child's latest snapshot.",
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 13,
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
                    _heroPill(
                      '${(state.masteryScore * 100).toStringAsFixed(0)}%',
                      'Mastery',
                    ),
                    const SizedBox(width: 8),
                    _heroPill(
                      '${(state.accuracy * 100).toStringAsFixed(0)}%',
                      'Accuracy',
                    ),
                    const SizedBox(width: 8),
                    _heroPill('${state.longestStreak}', 'Best streak'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Child activity card ──
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.child_care,
                        color: Color(0xFF6D4ACC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Child Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _activityRow(
                  Icons.quiz_outlined,
                  'Questions answered',
                  '${state.answeredCount}',
                  const Color(0xFF0A7B83),
                ),
                const SizedBox(height: 8),
                _activityRow(
                  Icons.local_fire_department_outlined,
                  'Best streak',
                  '${state.longestStreak}',
                  const Color(0xFFF69B45),
                ),
                const SizedBox(height: 8),
                _activityRow(
                  Icons.auto_stories_outlined,
                  'Recommended topic',
                  state.recommendedTopic ?? 'Mixed review',
                  const Color(0xFF5B67CA),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── At-home tips ──
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.home_outlined,
                        color: Color(0xFF27AE68),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'At-Home Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _tipRow(
                  'Ask your child to explain one question they got wrong',
                  const Color(0xFF0A7B83),
                ),
                const SizedBox(height: 8),
                _tipRow(
                  '10-min practice on ${weakestTopic ?? 'the recommended topic'}',
                  const Color(0xFFF69B45),
                ),
                const SizedBox(height: 8),
                _tipRow(
                  state.answeredCount == 0
                      ? 'Encourage your child to start their first quiz!'
                      : 'Celebrate their ${state.longestStreak}-answer best streak!',
                  const Color(0xFF27AE68),
                ),
              ],
            ),
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

  Widget _activityRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _tipRow(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.3)),
        ),
      ],
    );
  }
}

// ─────────────────── INSIGHTS ───────────────────

class _ParentInsightsTab extends ConsumerWidget {
  const _ParentInsightsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final masteryPct = (state.masteryScore * 100).toStringAsFixed(0);

    return ScreenBackground(
      child: ListView(
        children: [
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights,
                        color: Color(0xFF6D4ACC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Overall Mastery: $masteryPct%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Based on recent quiz sessions. Trend reflects adaptive difficulty.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (_) {
                    final trend = state.masteryTrend;
                    if (trend.length < 2) {
                      return const SizedBox(
                        height: 110,
                        child: Center(
                          child: Text(
                            'Complete 2+ quizzes to see the trend.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4F6773),
                            ),
                          ),
                        ),
                      );
                    }
                    return LineTrendChart(
                      points: trend,
                      color: const Color(0xFF6D4ACC),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (state.masteryByTopic.isNotEmpty)
            FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (final entry in state.masteryByTopic.entries) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: entry.value,
                              minHeight: 7,
                              backgroundColor: const Color(0xFFEEE0FF),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF6D4ACC),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${(entry.value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6D4ACC),
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.right,
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
}

// ─────────────────── PLANNER ───────────────────

class _ParentPlannerTab extends ConsumerWidget {
  const _ParentPlannerTab();

  static const _colors = [
    Color(0xFF0A7B83),
    Color(0xFF5B67CA),
    Color(0xFF6D4ACC),
    Color(0xFF27AE68),
    Color(0xFFF69B45),
    Color(0xFFE85D3C),
  ];
  static const _icons = [
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.quiz_outlined,
    Icons.menu_book_outlined,
    Icons.shuffle,
    Icons.emoji_events_outlined,
  ];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(quizControllerProvider);
    final notifier = ref.read(quizControllerProvider.notifier);
    final subjects = notifier.availableSubjects();
    final masteryMap = notifier.subjectMastery();

    final ordered = [...subjects]
      ..sort((a, b) => (masteryMap[a] ?? 0).compareTo(masteryMap[b] ?? 0));

    String activityFor(String subject, double mastery) {
      if (mastery < 0.4) return '$subject — intensive practice';
      if (mastery < 0.65) return '$subject — strengthen weak areas';
      return '$subject — challenge questions';
    }

    String durationFor(double mastery) => mastery < 0.5 ? '20 min' : '15 min';

    final s0 = ordered.isNotEmpty ? ordered[0] : 'Practice';
    final s1 = ordered.length > 1 ? ordered[1] : s0;
    final m0 = masteryMap[s0] ?? 0;
    final m1 = masteryMap[s1] ?? 0;

    final plans = [
      (
        day: _dayNames[0],
        activity: activityFor(s0, m0),
        duration: durationFor(m0),
        color: _colors[0],
        icon: _icons[0],
      ),
      (
        day: _dayNames[1],
        activity: activityFor(s1, m1),
        duration: durationFor(m1),
        color: _colors[1],
        icon: _icons[1],
      ),
      (
        day: _dayNames[2],
        activity: '$s0 — quiz yourself',
        duration: '10 min',
        color: _colors[2],
        icon: _icons[2],
      ),
      (
        day: _dayNames[3],
        activity: '$s1 — review key facts',
        duration: '12 min',
        color: _colors[3],
        icon: _icons[3],
      ),
      (
        day: _dayNames[4],
        activity: 'Mixed revision (all subjects)',
        duration: '20 min',
        color: _colors[4],
        icon: _icons[4],
      ),
      (
        day: _dayNames[5],
        activity: 'Reflection and rewards',
        duration: '10 min',
        color: _colors[5],
        icon: _icons[5],
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
                  'Weekly Study Plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Personalised based on your child\'s current mastery scores.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final plan in plans) ...[
            FrostedCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: plan.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      plan.day,
                      style: TextStyle(
                        color: plan.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: plan.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(plan.icon, color: plan.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      plan.activity,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: plan.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      plan.duration,
                      style: TextStyle(
                        color: plan.color,
                        fontSize: 12,
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

// ─────────────────── MESSAGES ───────────────────

class _ParentMessagesTab extends ConsumerWidget {
  const _ParentMessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);

    final messages =
        <
          ({
            String sender,
            String senderType,
            String text,
            Color color,
            IconData icon,
          })
        >[];

    if (state.answeredCount == 0) {
      messages.add((
        sender: 'Learning Coach',
        senderType: 'Tip',
        text: 'Encourage your child to start their first quiz session today!',
        color: const Color(0xFF0A7B83),
        icon: Icons.psychology_outlined,
      ));
    }

    if (state.longestStreak >= 3) {
      messages.add((
        sender: 'Learning Coach',
        senderType: 'Achievement',
        text:
            'Your child hit a ${state.longestStreak}-answer streak — great focus!',
        color: const Color(0xFFF69B45),
        icon: Icons.emoji_events_outlined,
      ));
    }

    if (state.totalXp > 0) {
      messages.add((
        sender: 'System',
        senderType: 'Update',
        text:
            'Your child has earned ${state.totalXp} XP so far. Keep the momentum going!',
        color: const Color(0xFF5B67CA),
        icon: Icons.stars_outlined,
      ));
    }

    if (state.masteryByTopic.isNotEmpty) {
      final weakest = state.masteryByTopic.entries.reduce(
        (a, b) => a.value < b.value ? a : b,
      );
      if (weakest.value < 0.6) {
        messages.add((
          sender: 'Learning Coach',
          senderType: 'Coach',
          text:
              '${weakest.key} is the current weakest topic '
              '(${(weakest.value * 100).toStringAsFixed(0)}%). A 10-min at-home review would help.',
          color: const Color(0xFFD05E1A),
          icon: Icons.lightbulb_outline,
        ));
      }
    }

    if (state.masteryTrend.length >= 2) {
      final first = state.masteryTrend.first;
      final last = state.masteryTrend.last;
      final delta = ((last - first) * 100).toStringAsFixed(0);
      final improving = last >= first;
      messages.add((
        sender: 'Learning Coach',
        senderType: 'Insight',
        text: improving
            ? 'Overall mastery has improved by $delta% across recent sessions. Excellent progress!'
            : 'Mastery has dipped by ${delta.replaceAll('-', '')}% recently. Extra practice this week would help.',
        color: improving ? const Color(0xFF27AE68) : const Color(0xFFE85D3C),
        icon: improving ? Icons.trending_up : Icons.trending_down,
      ));
    }

    if (messages.isEmpty) {
      messages.add((
        sender: 'Learning Coach',
        senderType: 'Info',
        text:
            'No updates yet. Complete a quiz to generate personalised insights.',
        color: const Color(0xFF4F6773),
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
                  'Messages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Personalised updates from your child\'s learning data.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4F6773)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final msg in messages) ...[
            FrostedCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: msg.color.withValues(alpha: 0.15),
                    child: Icon(msg.icon, color: msg.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              msg.sender,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: msg.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                msg.senderType,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: msg.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2E4C5A),
                            height: 1.4,
                          ),
                        ),
                      ],
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
