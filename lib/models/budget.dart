class Budget {
  final int? id;
  final String name;
  final String category;
  final double amount;
  final String? icon; // icon name string
  final int createdAt;

  const Budget({this.id, required this.name, required this.category, required this.amount, this.icon, required this.createdAt});

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'amount': amount,
        'icon': icon,
        'created_at': createdAt,
      };

  static Budget fromMap(Map<String, Object?> map) => Budget(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: map['category'] as String,
        amount: (map['amount'] as num).toDouble(),
        icon: map['icon'] as String?,
        createdAt: map['created_at'] as int,
      );
}


