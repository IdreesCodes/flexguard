import '../utils/constants.dart';

class AppTransaction {
  final int? id;
  final int userId;
  final TransactionType type;
  final double amount;
  final String? category;
  final String? note;
  final int date; // epoch millis
  final int? budgetId;
  final int? goalId;

  const AppTransaction({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.category,
    this.note,
    required this.date,
    this.budgetId,
    this.goalId,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date,
        'budget_id': budgetId,
        'goal_id': goalId,
      };

  static AppTransaction fromMap(Map<String, Object?> map) => AppTransaction(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        type: TransactionType.values.firstWhere((e) => e.name == (map['type'] as String)),
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String?,
        note: map['note'] as String?,
        date: map['date'] as int,
        budgetId: map['budget_id'] as int?,
        goalId: map['goal_id'] as int?,
      );
}


