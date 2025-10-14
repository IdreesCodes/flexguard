import '../utils/db_helper.dart';

class RiskSignal {
  final String label;
  final String message;
  final int score; // 0-100
  const RiskSignal({required this.label, required this.message, required this.score});
}

class RiskAnalyzer {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<RiskSignal>> analyze({required int userId}) async {
    final now = DateTime.now();
    final List<RiskSignal> signals = [];

    // Time-based: late night or weekend
    final isLate = now.hour >= 22 || now.hour <= 6;
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    if (isLate) {
      signals.add(const RiskSignal(label: 'Late-night risk', message: 'Most impulse purchases happen late. Consider delaying until morning.', score: 40));
    }
    if (isWeekend) {
      signals.add(const RiskSignal(label: 'Weekend risk', message: 'Weekend spending tends to spike. Double-check if this is essential.', score: 25));
    }

    // Recency: multiple expenses in last 60 minutes
    final lastHour = now.subtract(const Duration(minutes: 60)).millisecondsSinceEpoch;
    final recent = await _db.getExpensesSince(userId: userId, sinceMillis: lastHour);
    if (recent.length >= 2) {
      signals.add(RiskSignal(label: 'Impulse streak', message: 'You made ${recent.length} expenses in the last hour.', score: 50));
    }

    // Emotion logs in last 24h with stress/bored triggers
    final db = await _db.database;
    final lastDay = now.subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
    final emo = await db.query('emotions',
        where: 'user_id = ? AND date >= ?', whereArgs: [userId, lastDay], orderBy: 'date DESC');
    final hasStress = emo.any((e) {
      final em = (e['emotion'] as String).toLowerCase();
      final trg = (e['trigger'] as String?)?.toLowerCase();
      return em.contains('stress') || em.contains('bored') || (trg != null && (trg.contains('social') || trg.contains('late')));
    });
    if (hasStress) {
      signals.add(const RiskSignal(label: 'Emotional spend risk', message: 'Recent mood/trigger suggests a higher chance of impulse buys.', score: 45));
    }

    // Score-normalize and cap to unique labels
    return signals;
  }
}


