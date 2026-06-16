import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_session_state.dart';

final localProgressStoreProvider = Provider<LocalProgressStore>((ref) {
  return const LocalProgressStore();
});

class LocalProgressStore {
  const LocalProgressStore();

  static const _summaryKey = 'latest_session_summary';
  static const _masteryTrendKey = 'mastery_trend_scores';
  static const _lifetimeKey = 'lifetime_progress';
  static const _askedIdsPrefix = 'asked_ids_';

  Future<void> saveCompletedSession(QuizSessionState state) async {
    final prefs = await SharedPreferences.getInstance();

    final summary = <String, dynamic>{
      'studentName': state.studentName,
      'subject': state.selectedSubject,
      'accuracy': state.accuracy,
      'masteryScore': state.masteryScore,
      'longestStreak': state.longestStreak,
      'recommendedTopic': state.recommendedTopic,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_summaryKey, jsonEncode(summary));

    final trend = await loadMasteryTrend();
    trend.add(state.masteryScore);
    final capped = trend.length > 14 ? trend.sublist(trend.length - 14) : trend;
    await prefs.setStringList(
      _masteryTrendKey,
      capped.map((v) => v.toStringAsFixed(4)).toList(),
    );
  }

  Future<Map<String, dynamic>?> loadLatestSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_summaryKey);
    if (raw == null) {
      return null;
    }

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<double>> loadMasteryTrend() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_masteryTrendKey) ?? const <String>[];
    return list
        .map((value) => double.tryParse(value) ?? 0)
        .where((value) => value > 0)
        .toList();
  }

  Future<void> saveMasteryTrend(List<double> trend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _masteryTrendKey,
      trend.map((v) => v.toStringAsFixed(4)).toList(),
    );
  }

  // ── Lifetime progress (mastery, cumulative stats) ──────────────────────────

  Future<void> saveLifetimeProgress({
    required Map<String, double> masteryByTopic,
    required int correctAnswers,
    required int wrongAnswers,
    required int longestStreak,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'masteryByTopic': masteryByTopic,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'longestStreak': longestStreak,
    };
    await prefs.setString(_lifetimeKey, jsonEncode(data));
  }

  Future<
    ({
      Map<String, double> masteryByTopic,
      int correctAnswers,
      int wrongAnswers,
      int longestStreak,
    })?
  >
  loadLifetimeProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lifetimeKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final mastery = (data['masteryByTopic'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
      return (
        masteryByTopic: mastery,
        correctAnswers: (data['correctAnswers'] as num).toInt(),
        wrongAnswers: (data['wrongAnswers'] as num).toInt(),
        longestStreak: (data['longestStreak'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Asked question IDs per subject ─────────────────────────────────────────

  Future<void> saveAskedQuestionIds(String subject, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_askedIdsPrefix$subject', ids.toList());
  }

  Future<Set<String>> loadAskedQuestionIds(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final list =
        prefs.getStringList('$_askedIdsPrefix$subject') ?? const <String>[];
    return list.toSet();
  }

  // ── XP ─────────────────────────────────────────────────────────────────────

  Future<void> saveXp(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_xp', xp);
  }

  Future<int> loadXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('total_xp') ?? 0;
  }

  // ── Daily goals (date-keyed, reset each new day) ────────────────────────────

  Future<void> saveDailyGoals(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(
      'daily_goals',
      jsonEncode({'date': today, 'ids': ids.toList()}),
    );
  }

  Future<Set<String>> loadTodayDailyGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('daily_goals');
    if (raw == null) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (data['date'] != today) return {};
      return (data['ids'] as List<dynamic>).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }
}
