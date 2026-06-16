import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

class AiQuestionService {
  const AiQuestionService();

  static const _dartDefineKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const _prefsKey = 'anthropic_api_key';
  static const _model = 'claude-3-5-haiku-20241022';
  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  /// Saves [key] to SharedPreferences so the user doesn't need --dart-define.
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.trim());
  }

  /// Resolves the API key: dart-define takes priority, then stored prefs.
  static Future<String> resolveApiKey() async {
    if (_dartDefineKey.isNotEmpty) return _dartDefineKey;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? '';
  }

  Future<List<Question>> generateQuestions(
    String subject,
    List<String> topics,
  ) async {
    final apiKey = await AiQuestionService.resolveApiKey();
    if (apiKey.isEmpty) {
      throw const AiKeyMissingException();
    }

    final topicsStr = topics.join(', ');
    final prompt =
        '''Generate exactly 12 multiple-choice quiz questions for a '''
        '''middle-school student studying $subject.
Cover a mix of these topics: $topicsStr.

Return ONLY a JSON array — no markdown, no code fences, no extra text.
Each element must have exactly these fields:
{
  "id": "unique short string, e.g. q1",
  "subject": "$subject",
  "topic": "one of: $topicsStr",
  "prompt": "the question text",
  "options": ["A", "B", "C", "D"],
  "correctIndex": 0,
  "difficulty": "easy",
  "hint": "a short clue for a stuck student",
  "explanation": "brief explanation of why the answer is correct"
}

Rules:
- "correctIndex" is the 0-based index of the correct option in "options".
- "difficulty" must be exactly "easy", "medium", or "hard".
- Include 4 easy, 4 medium, and 4 hard questions.
- Vary the topics — do not put all questions on the same topic.''';

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'max_tokens': 4096,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AiApiException(response.statusCode, response.body);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        ((body['content'] as List<dynamic>)[0] as Map<String, dynamic>)['text']
            as String;

    // Strip any accidental markdown code fences (multiLine so ^ and $ match per-line).
    final clean = text
        .trim()
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
        .trim();

    final raw = jsonDecode(clean) as List<dynamic>;
    return raw.asMap().entries.map((entry) {
      final obj = entry.value as Map<String, dynamic>;
      final options = (obj['options'] as List<dynamic>)
          .map((o) => o.toString())
          .toList();
      final correctIndex = ((obj['correctIndex'] as num?)?.toInt() ?? 0).clamp(
        0,
        options.length - 1,
      );
      return Question(
        id: (obj['id'] as String?) ?? '${subject.toLowerCase()}_${entry.key}',
        subject: subject,
        topic: (obj['topic'] as String?) ?? subject,
        prompt: obj['prompt'] as String,
        options: options,
        correctIndex: correctIndex,
        difficulty: _parseDifficulty(obj['difficulty'] as String? ?? 'medium'),
        hint: (obj['hint'] as String?) ?? '',
        explanation: (obj['explanation'] as String?) ?? '',
      );
    }).toList();
  }

  QuestionDifficulty _parseDifficulty(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return QuestionDifficulty.easy;
      case 'hard':
        return QuestionDifficulty.hard;
      default:
        return QuestionDifficulty.medium;
    }
  }
}

class AiKeyMissingException implements Exception {
  const AiKeyMissingException();

  @override
  String toString() =>
      'ANTHROPIC_API_KEY is not set. '
      'Run the app with: flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...';
}

class AiApiException implements Exception {
  const AiApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'Anthropic API error $statusCode: $body';
}
