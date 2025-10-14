class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final int createdAt;
  final int updatedAt;

  const Goal({this.id, required this.name, required this.targetAmount, required this.savedAmount, required this.createdAt, required this.updatedAt});

  double get progress => targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);

  Goal copyWith({int? id, String? name, double? targetAmount, double? savedAmount, int? createdAt, int? updatedAt}) => Goal(
        id: id ?? this.id,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  static Goal fromMap(Map<String, Object?> map) => Goal(
        id: map['id'] as int?,
        name: map['name'] as String,
        targetAmount: (map['target_amount'] as num).toDouble(),
        savedAmount: (map['saved_amount'] as num).toDouble(),
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );
}


