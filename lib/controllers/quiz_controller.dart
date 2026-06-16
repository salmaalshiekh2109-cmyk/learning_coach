import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_repository.dart';
import '../services/local_progress_store.dart';
import '../logic/adaptive_quiz_engine.dart';
import '../models/question.dart';
import '../models/quiz_session_state.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return const QuestionRepository();
});

final adaptiveQuizEngineProvider = Provider<AdaptiveQuizEngine>((ref) {
  return AdaptiveQuizEngine();
});

final quizControllerProvider =
    NotifierProvider<QuizController, QuizSessionState>(QuizController.new);

class QuizController extends Notifier<QuizSessionState> {
  late QuestionRepository _repository;
  late AdaptiveQuizEngine _adaptiveEngine;

  @override
  QuizSessionState build() {
    _repository = ref.watch(questionRepositoryProvider);
    _adaptiveEngine = ref.watch(adaptiveQuizEngineProvider);
    Future.microtask(_initFromPersisted);
    return QuizSessionState.empty();
  }

  /// Loads persisted lifetime stats + XP + daily goals into state.
  /// Only runs when no quiz is active (safe from build()).
  Future<void> _initFromPersisted() async {
    final store = ref.read(localProgressStoreProvider);
    final persisted = await store.loadLifetimeProgress();
    final xp = await store.loadXp();
    final dailyGoals = await store.loadTodayDailyGoals();
    final trend = await store.loadMasteryTrend();
    if (state.isGenerating || state.selectedSubject.isNotEmpty) return;
    state = state.copyWith(
      masteryByTopic: persisted?.masteryByTopic ?? const {},
      correctAnswers: persisted?.correctAnswers ?? 0,
      wrongAnswers: persisted?.wrongAnswers ?? 0,
      longestStreak: persisted?.longestStreak ?? 0,
      totalXp: xp,
      goalsAwardedToday: dailyGoals,
      masteryTrend: trend,
    );
  }

  List<String> availableSubjects() => _repository.subjects();

  /// Per-subject mastery: average of all topic masteries within each subject.
  Map<String, double> subjectMastery() {
    final byTopic = state.masteryByTopic;
    final result = <String, double>{};
    for (final subject in _repository.subjects()) {
      final topics = _repository.topicsForSubject(subject);
      final scores = topics.map((t) => byTopic[t]).whereType<double>().toList();
      result[subject] = scores.isEmpty
          ? 0.0
          : scores.reduce((a, b) => a + b) / scores.length;
    }
    return result;
  }

  /// Sets the loading state synchronously then kicks off async question
  /// generation so the caller can navigate to QuizScreen immediately.
  void startQuizLoading({
    required String studentName,
    required String subject,
  }) {
    state = QuizSessionState(
      studentName: studentName,
      selectedSubject: subject,
      currentQuestion: null,
      answeredQuestionIds: const <String>{},
      history: const <AnswerRecord>[],
      recentResults: const <bool>[],
      masteryByTopic: const <String, double>{},
      totalQuestions: 0,
      correctAnswers: state.correctAnswers,
      wrongAnswers: state.wrongAnswers,
      currentStreak: 0,
      longestStreak: state.longestStreak,
      currentDifficulty: QuestionDifficulty.medium,
      completed: false,
      sessionStart: null,
      recommendedTopic: null,
      isGenerating: true,
      questionPool: const <Question>[],
      generationError: null,
      totalXp: state.totalXp,
      goalsAwardedToday: state.goalsAwardedToday,
      masteryTrend: state.masteryTrend,
    );
    unawaited(_loadQuestions(studentName: studentName, subject: subject));
  }

  Future<void> _loadQuestions({
    required String studentName,
    required String subject,
  }) async {
    final store = ref.read(localProgressStoreProvider);
    List<Question> allQuestions;

    try {
      allQuestions = await _repository.questionsForSubject(subject);
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        generationError: e.toString(),
      );
      return;
    }

    // Load persisted lifetime data.
    final persisted = await store.loadLifetimeProgress();
    final existingMastery =
        persisted?.masteryByTopic ?? const <String, double>{};
    final lifetimeCorrect = persisted?.correctAnswers ?? 0;
    final lifetimeWrong = persisted?.wrongAnswers ?? 0;
    final lifetimeBestStreak = persisted?.longestStreak ?? 0;

    // Merge persisted per-topic mastery with defaults for new topics.
    final initialMastery = <String, double>{
      for (final q in allQuestions) q.topic: existingMastery[q.topic] ?? 0.5,
    };

    // Load cross-session asked IDs so questions aren't repeated.
    var askedIds = await store.loadAskedQuestionIds(subject);
    final available = allQuestions
        .where((q) => !askedIds.contains(q.id))
        .toList();
    if (available.isEmpty) {
      askedIds = {};
      await store.saveAskedQuestionIds(subject, {});
    }
    final freshPool = available.isEmpty ? allQuestions : available;
    final total = min(8, freshPool.length);

    final firstQuestion = _adaptiveEngine.selectNextQuestion(
      questionPool: freshPool,
      askedQuestionIds: askedIds,
      currentDifficulty: QuestionDifficulty.medium,
      recentResults: const <bool>[],
    );

    state = QuizSessionState(
      studentName: studentName,
      selectedSubject: subject,
      currentQuestion: firstQuestion,
      answeredQuestionIds: askedIds,
      history: const <AnswerRecord>[],
      recentResults: const <bool>[],
      masteryByTopic: initialMastery,
      totalQuestions: total,
      correctAnswers: lifetimeCorrect,
      wrongAnswers: lifetimeWrong,
      currentStreak: 0,
      longestStreak: lifetimeBestStreak,
      currentDifficulty: QuestionDifficulty.medium,
      completed: firstQuestion == null,
      sessionStart: DateTime.now(),
      recommendedTopic: null,
      isGenerating: false,
      questionPool: allQuestions,
      generationError: null,
      totalXp: state.totalXp,
      goalsAwardedToday: state.goalsAwardedToday,
      masteryTrend: state.masteryTrend,
    );
  }

  bool submitAnswer(int selectedIndex) {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null || state.completed) {
      return false;
    }

    final isCorrect = currentQuestion.correctIndex == selectedIndex;
    final updatedMastery = Map<String, double>.from(state.masteryByTopic);
    final previousMastery = updatedMastery[currentQuestion.topic] ?? 0.5;
    updatedMastery[currentQuestion.topic] = _updatedMastery(
      previous: previousMastery,
      isCorrect: isCorrect,
    );

    final answeredQuestionIds = Set<String>.from(state.answeredQuestionIds)
      ..add(currentQuestion.id);

    final newHistory = <AnswerRecord>[
      ...state.history,
      AnswerRecord(
        question: currentQuestion,
        selectedIndex: selectedIndex,
        isCorrect: isCorrect,
      ),
    ];

    final newRecent = <bool>[...state.recentResults, isCorrect];
    if (newRecent.length > 5) {
      newRecent.removeAt(0);
    }

    final currentStreak = isCorrect ? state.currentStreak + 1 : 0;
    final longestStreak = max(state.longestStreak, currentStreak);
    final nextDifficulty = _nextDifficulty(
      current: state.currentDifficulty,
      isCorrect: isCorrect,
    );

    final allQuestions = state.questionPool;
    final done = newHistory.length >= state.totalQuestions;

    final nextQuestion = done
        ? null
        : _adaptiveEngine.selectNextQuestion(
            questionPool: allQuestions,
            askedQuestionIds: answeredQuestionIds,
            currentDifficulty: nextDifficulty,
            recentResults: newRecent,
          );

    final newCorrect = state.correctAnswers + (isCorrect ? 1 : 0);
    final newWrong = state.wrongAnswers + (isCorrect ? 0 : 1);
    final sessionDone = done || nextQuestion == null;

    state = state.copyWith(
      answeredQuestionIds: answeredQuestionIds,
      history: newHistory,
      recentResults: newRecent,
      masteryByTopic: updatedMastery,
      correctAnswers: newCorrect,
      wrongAnswers: newWrong,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      currentDifficulty: nextDifficulty,
      currentQuestion: nextQuestion,
      clearCurrentQuestion: sessionDone,
      completed: sessionDone,
      recommendedTopic: sessionDone ? _recommendedTopic(updatedMastery) : null,
      clearRecommendation: !sessionDone,
    );

    // ── Daily goal auto-award ───────────────────────────────────────────────
    final sessionCorrect = newHistory.where((r) => r.isCorrect).length;
    final sessionTopics = newHistory
        .map((r) => r.question.topic)
        .toSet()
        .length;
    final awardedGoals = Set<String>.from(state.goalsAwardedToday);
    var xpGain = 0;
    if (sessionCorrect >= 5 && !awardedGoals.contains('correct_5')) {
      awardedGoals.add('correct_5');
      xpGain += 20;
    }
    if (currentStreak >= 3 && !awardedGoals.contains('streak_3')) {
      awardedGoals.add('streak_3');
      xpGain += 20;
    }
    if (sessionTopics >= 3 && !awardedGoals.contains('topics_3')) {
      awardedGoals.add('topics_3');
      xpGain += 30;
    }
    if (sessionDone &&
        newHistory.isNotEmpty &&
        !awardedGoals.contains('finish_quiz')) {
      awardedGoals.add('finish_quiz');
      xpGain += 25;
    }
    if (xpGain > 0) {
      final newXp = state.totalXp + xpGain;
      state = state.copyWith(totalXp: newXp, goalsAwardedToday: awardedGoals);
    }

    if (sessionDone) {
      // Append this session's mastery score to the trend.
      final newTrend = List<double>.from(state.masteryTrend)
        ..add(state.masteryScore);
      final capped = newTrend.length > 20
          ? newTrend.sublist(newTrend.length - 20)
          : newTrend;
      state = state.copyWith(masteryTrend: capped);
      // Persist lifetime progress so stats survive app restarts.
      final store = ref.read(localProgressStoreProvider);
      unawaited(
        store.saveLifetimeProgress(
          masteryByTopic: updatedMastery,
          correctAnswers: newCorrect,
          wrongAnswers: newWrong,
          longestStreak: longestStreak,
        ),
      );
      unawaited(
        store.saveAskedQuestionIds(state.selectedSubject, answeredQuestionIds),
      );
      unawaited(store.saveXp(state.totalXp));
      unawaited(store.saveDailyGoals(state.goalsAwardedToday));
      unawaited(store.saveCompletedSession(state));
      // Persist the updated trend directly from state.
      unawaited(store.saveMasteryTrend(state.masteryTrend));
    }

    return isCorrect;
  }

  void resetSession() {
    state = QuizSessionState.empty();
  }

  /// Clears any generation error and retries loading questions for the
  /// current subject. Call this after the user has saved a valid API key.
  void retryGeneration() {
    final subject = state.selectedSubject;
    final studentName = state.studentName;
    if (subject.isEmpty) return;
    state = state.copyWith(isGenerating: true, clearGenerationError: true);
    // Force-bust the cache in case a bad response was cached.
    unawaited(
      _repository
          .refreshSubject(subject)
          .then((_) async {
            // refreshSubject already cleared the cache; now do the full load.
          })
          .catchError((_) {}),
    );
    unawaited(_loadQuestions(studentName: studentName, subject: subject));
  }

  double _updatedMastery({required double previous, required bool isCorrect}) {
    const alpha = 0.3;
    final outcome = isCorrect ? 1.0 : 0.0;
    return (previous * (1 - alpha) + outcome * alpha).clamp(0.0, 1.0);
  }

  QuestionDifficulty _nextDifficulty({
    required QuestionDifficulty current,
    required bool isCorrect,
  }) {
    final delta = isCorrect ? 1 : -1;
    final nextLevel = (current.level + delta).clamp(1, 3);
    return QuestionDifficulty.values[nextLevel - 1];
  }

  String _recommendedTopic(Map<String, double> masteryByTopic) {
    if (masteryByTopic.isEmpty) {
      return 'Review fundamentals';
    }

    var weakestTopic = masteryByTopic.keys.first;
    var lowestScore = masteryByTopic[weakestTopic] ?? 0;

    masteryByTopic.forEach((topic, score) {
      if (score < lowestScore) {
        weakestTopic = topic;
        lowestScore = score;
      }
    });

    return weakestTopic;
  }
}
