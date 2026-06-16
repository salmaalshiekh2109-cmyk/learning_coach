import 'question.dart';

class AnswerRecord {
  const AnswerRecord({
    required this.question,
    required this.selectedIndex,
    required this.isCorrect,
  });

  final Question question;
  final int selectedIndex;
  final bool isCorrect;
}

class QuizSessionState {
  const QuizSessionState({
    required this.studentName,
    required this.selectedSubject,
    required this.currentQuestion,
    required this.answeredQuestionIds,
    required this.history,
    required this.recentResults,
    required this.masteryByTopic,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.currentStreak,
    required this.longestStreak,
    required this.currentDifficulty,
    required this.completed,
    required this.sessionStart,
    required this.recommendedTopic,
    required this.isGenerating,
    required this.questionPool,
    required this.generationError,
    required this.totalXp,
    required this.goalsAwardedToday,
    required this.masteryTrend,
  });

  factory QuizSessionState.empty() => QuizSessionState(
    studentName: '',
    selectedSubject: '',
    currentQuestion: null,
    answeredQuestionIds: const <String>{},
    history: const <AnswerRecord>[],
    recentResults: const <bool>[],
    masteryByTopic: const <String, double>{},
    totalQuestions: 0,
    correctAnswers: 0,
    wrongAnswers: 0,
    currentStreak: 0,
    longestStreak: 0,
    currentDifficulty: QuestionDifficulty.medium,
    completed: false,
    sessionStart: null,
    recommendedTopic: null,
    isGenerating: false,
    questionPool: const <Question>[],
    generationError: null,
    totalXp: 0,
    goalsAwardedToday: const <String>{},
    masteryTrend: const <double>[],
  );

  final String studentName;
  final String selectedSubject;
  final Question? currentQuestion;
  final Set<String> answeredQuestionIds;
  final List<AnswerRecord> history;
  final List<bool> recentResults;
  final Map<String, double> masteryByTopic;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int currentStreak;
  final int longestStreak;
  final QuestionDifficulty currentDifficulty;
  final bool completed;
  final DateTime? sessionStart;
  final String? recommendedTopic;
  final bool isGenerating;
  final List<Question> questionPool;
  final String? generationError;
  final int totalXp;
  final Set<String> goalsAwardedToday;
  final List<double> masteryTrend;

  int get answeredCount => correctAnswers + wrongAnswers;

  double get accuracy =>
      answeredCount == 0 ? 0 : correctAnswers / answeredCount;

  double get masteryScore {
    if (masteryByTopic.isEmpty) {
      return accuracy;
    }
    final total = masteryByTopic.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    return total / masteryByTopic.length;
  }

  int get estimatedMinutesSpent {
    if (sessionStart == null) {
      return 0;
    }
    final elapsed = DateTime.now().difference(sessionStart!);
    return elapsed.inMinutes.clamp(0, 120);
  }

  QuizSessionState copyWith({
    String? studentName,
    String? selectedSubject,
    Question? currentQuestion,
    bool clearCurrentQuestion = false,
    Set<String>? answeredQuestionIds,
    List<AnswerRecord>? history,
    List<bool>? recentResults,
    Map<String, double>? masteryByTopic,
    int? totalQuestions,
    int? correctAnswers,
    int? wrongAnswers,
    int? currentStreak,
    int? longestStreak,
    QuestionDifficulty? currentDifficulty,
    bool? completed,
    DateTime? sessionStart,
    String? recommendedTopic,
    bool clearRecommendation = false,
    bool? isGenerating,
    List<Question>? questionPool,
    String? generationError,
    bool clearGenerationError = false,
    int? totalXp,
    Set<String>? goalsAwardedToday,
    List<double>? masteryTrend,
  }) {
    return QuizSessionState(
      studentName: studentName ?? this.studentName,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      currentQuestion: clearCurrentQuestion
          ? null
          : (currentQuestion ?? this.currentQuestion),
      answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
      history: history ?? this.history,
      recentResults: recentResults ?? this.recentResults,
      masteryByTopic: masteryByTopic ?? this.masteryByTopic,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      completed: completed ?? this.completed,
      sessionStart: sessionStart ?? this.sessionStart,
      recommendedTopic: clearRecommendation
          ? null
          : (recommendedTopic ?? this.recommendedTopic),
      isGenerating: isGenerating ?? this.isGenerating,
      questionPool: questionPool ?? this.questionPool,
      generationError: clearGenerationError
          ? null
          : (generationError ?? this.generationError),
      totalXp: totalXp ?? this.totalXp,
      goalsAwardedToday: goalsAwardedToday ?? this.goalsAwardedToday,
      masteryTrend: masteryTrend ?? this.masteryTrend,
    );
  }
}
