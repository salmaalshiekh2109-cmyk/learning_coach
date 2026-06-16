enum QuestionDifficulty {
  easy(1),
  medium(2),
  hard(3);

  const QuestionDifficulty(this.level);
  final int level;

  String get label {
    switch (this) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }
}

class Question {
  const Question({
    required this.id,
    required this.subject,
    required this.topic,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.hint,
    required this.explanation,
  });

  final String id;
  final String subject;
  final String topic;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final QuestionDifficulty difficulty;
  final String hint;
  final String explanation;
}
