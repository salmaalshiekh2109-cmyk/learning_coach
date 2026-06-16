import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final analyticsApiServiceProvider = Provider<AnalyticsApiService>((ref) {
  return const AnalyticsApiService();
});

class AnalyticsApiService {
  const AnalyticsApiService();

  Future<TeacherAnalyticsSnapshot> fetchClassSnapshot({
    required String subject,
  }) async {
    // Demo-first API design: call can be swapped to a real endpoint later.
    final uri = Uri.parse('https://example.com/api/class?subject=$subject');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return TeacherAnalyticsSnapshot.fromJson(decoded);
      }
    } catch (_) {
      // Fallback below keeps teacher dashboard functional offline.
    }

    return TeacherAnalyticsSnapshot.fallback(subject: subject);
  }
}

class TeacherAnalyticsSnapshot {
  const TeacherAnalyticsSnapshot({
    required this.classAverage,
    required this.strugglingTopics,
    required this.commonMistakes,
    required this.weeklyMastery,
  });

  factory TeacherAnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return TeacherAnalyticsSnapshot(
      classAverage: (json['classAverage'] as num?)?.toDouble() ?? 0.66,
      strugglingTopics:
          (json['strugglingTopics'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString())
              .toList(),
      commonMistakes:
          (json['commonMistakes'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString())
              .toList(),
      weeklyMastery:
          (json['weeklyMastery'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => (e as num).toDouble())
              .toList(),
    );
  }

  factory TeacherAnalyticsSnapshot.fallback({required String subject}) {
    return TeacherAnalyticsSnapshot(
      classAverage: 0.71,
      strugglingTopics: <String>['Fractions', 'Algebra'],
      commonMistakes: <String>[
        'Rushing multi-step equation solving',
        'Mixing numerator/denominator operations',
      ],
      weeklyMastery: <double>[0.51, 0.56, 0.59, 0.63, 0.67, 0.7, 0.71],
    );
  }

  final double classAverage;
  final List<String> strugglingTopics;
  final List<String> commonMistakes;
  final List<double> weeklyMastery;
}
