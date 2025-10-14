class UpcomingPayment {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final int dueDate;
  final String? category;
  final String? recurring; // none, monthly, yearly
  final int createdAt;

  const UpcomingPayment({this.id, required this.userId, required this.title, required this.amount, required this.dueDate, this.category, this.recurring, required this.createdAt});

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'amount': amount,
        'due_date': dueDate,
        'category': category,
        'recurring': recurring,
        'created_at': createdAt,
      };

  static UpcomingPayment fromMap(Map<String, Object?> m) => UpcomingPayment(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        dueDate: m['due_date'] as int,
        category: m['category'] as String?,
        recurring: m['recurring'] as String?,
        createdAt: m['created_at'] as int,
      );
}


