import 'dart:math';

import '../models/question.dart';

class AdaptiveQuizEngine {
  AdaptiveQuizEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  Question? selectNextQuestion({
    required List<Question> questionPool,
    required Set<String> askedQuestionIds,
    required QuestionDifficulty currentDifficulty,
    required List<bool> recentResults,
  }) {
    final available = questionPool
        .where((q) => !askedQuestionIds.contains(q.id))
        .toList();
    if (available.isEmpty) {
      return null;
    }

    final targetLevel = _targetDifficultyLevel(
      baseLevel: currentDifficulty.level,
      recentResults: recentResults,
    );

    available.sort((a, b) {
      final byDistance = (a.difficulty.level - targetLevel).abs().compareTo(
        (b.difficulty.level - targetLevel).abs(),
      );
      if (byDistance != 0) {
        return byDistance;
      }
      return a.topic.compareTo(b.topic);
    });

    final topDistance = (available.first.difficulty.level - targetLevel).abs();
    final bestMatches = available
        .where(
          (question) =>
              (question.difficulty.level - targetLevel).abs() == topDistance,
        )
        .toList();

    return bestMatches[_random.nextInt(bestMatches.length)];
  }

  int _targetDifficultyLevel({
    required int baseLevel,
    required List<bool> recentResults,
  }) {
    if (recentResults.length < 2) {
      return baseLevel;
    }

    final window = recentResults.length > 3
        ? recentResults.sublist(recentResults.length - 3)
        : recentResults;
    final correct = window.where((value) => value).length;
    final accuracy = correct / window.length;

    if (accuracy >= 0.67) {
      return (baseLevel + 1).clamp(1, 3);
    }
    if (accuracy <= 0.34) {
      return (baseLevel - 1).clamp(1, 3);
    }
    return baseLevel;
  }
}
