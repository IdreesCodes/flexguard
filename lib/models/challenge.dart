class Challenge {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final int? deadline;
  final int createdAt;

  const Challenge({this.id, required this.name, required this.targetAmount, required this.savedAmount, this.deadline, required this.createdAt});

  double get progress => targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'deadline': deadline,
        'created_at': createdAt,
      };

  static Challenge fromMap(Map<String, Object?> m) => Challenge(
        id: m['id'] as int?,
        name: m['name'] as String,
        targetAmount: (m['target_amount'] as num).toDouble(),
        savedAmount: (m['saved_amount'] as num).toDouble(),
        deadline: m['deadline'] as int?,
        createdAt: m['created_at'] as int,
      );
}


