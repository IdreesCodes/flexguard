class EmotionLog {
  final int? id;
  final int userId;
  final int? transactionId;
  final String emotion; // e.g., bored, stressed, excited
  final int intensity; // 1-5
  final String? note;
  final String? trigger; // context, e.g., social media, late night, with friends
  final int date;

  const EmotionLog({this.id, required this.userId, this.transactionId, required this.emotion, required this.intensity, this.note, this.trigger, required this.date});

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'transaction_id': transactionId,
        'emotion': emotion,
        'intensity': intensity,
        'note': note,
        'date': date,
        'trigger': trigger,
      };

  static EmotionLog fromMap(Map<String, Object?> m) => EmotionLog(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        transactionId: m['transaction_id'] as int?,
        emotion: m['emotion'] as String,
        intensity: m['intensity'] as int,
        note: m['note'] as String?,
        trigger: m['trigger'] as String?,
        date: m['date'] as int,
      );
}


