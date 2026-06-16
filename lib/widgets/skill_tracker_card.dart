import 'package:flutter/material.dart';

class SkillTrackerCard extends StatelessWidget {
  const SkillTrackerCard({
    super.key,
    required this.topic,
    required this.mastery,
    required this.accuracy,
  });

  final String topic;
  final double mastery;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final palette = _masteryPalette(mastery);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(mastery * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: mastery,
            minHeight: 8,
            color: palette.progress,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: Colors.white.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 9),
          Text(
            'Accuracy ${(accuracy * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5A6A)),
          ),
        ],
      ),
    );
  }

  ({Color background, Color border, Color progress, Color text})
  _masteryPalette(double score) {
    if (score >= 0.75) {
      return (
        background: const Color(0xFFE8F8F0),
        border: const Color(0xFF96D9B8),
        progress: const Color(0xFF1E9B5C),
        text: const Color(0xFF0C6A3D),
      );
    }
    if (score >= 0.45) {
      return (
        background: const Color(0xFFFFF6E5),
        border: const Color(0xFFFFD58A),
        progress: const Color(0xFFF08A24),
        text: const Color(0xFF9B5C12),
      );
    }
    return (
      background: const Color(0xFFFFECEB),
      border: const Color(0xFFFFB6AF),
      progress: const Color(0xFFD84D3F),
      text: const Color(0xFF8F251D),
    );
  }
}
