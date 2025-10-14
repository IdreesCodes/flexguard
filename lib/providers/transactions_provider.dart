import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../utils/db_helper.dart';

class TransactionsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final int userId;

  TransactionsProvider({required this.userId});

  final List<AppTransaction> _transactions = [];
  bool _isFetching = false;
  bool _hasMore = true;
  double _balance = 0;

  List<AppTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isFetching => _isFetching;
  bool get hasMore => _hasMore;
  double get balance => _balance;

  Future<void> refresh() async {
    _transactions.clear();
    _hasMore = true;
    notifyListeners();
    await Future.wait([fetchMore(reset: true), _updateBalance()]);
  }

  Future<void> _updateBalance() async {
    _balance = await _db.getBalance(userId: userId);
    notifyListeners();
  }

  Future<void> fetchMore({bool reset = false}) async {
    if (_isFetching || !_hasMore) return;
    _isFetching = true;
    notifyListeners();
    try {
      final rows = await _db.getTransactionsPaged(userId: userId, offset: _transactions.length, limit: 20);
      final newItems = rows.map(AppTransaction.fromMap).toList();
      _transactions.addAll(newItems);
      if (newItems.length < 20) _hasMore = false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<List<AppTransaction>> getRecent({int limit = 3}) async {
    final rows = await _db.getRecentTransactions(userId: userId, limit: limit);
    return rows.map(AppTransaction.fromMap).toList();
  }

  Future<Map<DateTime, double>> last7DaysSpending() async {
    final now = DateTime.now();
    final rows = await _db.getLast7DaysSpending(userId: userId, nowMillis: now.millisecondsSinceEpoch);
    final Map<DateTime, double> result = {};
    for (final r in rows) {
      final dayStr = r['day'] as String; // yyyy-MM-dd
      final parts = dayStr.split('-');
      final day = DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      result[day] = (r['total'] as num).toDouble();
    }
    // Ensure all 7 days exist
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: i));
      result[d] = result[d] ?? 0;
    }
    return result;
  }

  Future<void> add(AppTransaction tx) async {
    // Auto-link to budget by category if exists
    if (tx.category != null && tx.category!.isNotEmpty) {
      final b = await _db.getBudgetByCategory(tx.category!);
      if (b != null) {
        tx = AppTransaction(
          id: tx.id,
          userId: tx.userId,
          type: tx.type,
          amount: tx.amount,
          category: tx.category,
          note: tx.note,
          date: tx.date,
          budgetId: b['id'] as int?,
          goalId: tx.goalId,
        );
      }
    }
    await _db.insertTransaction(tx.toMap());
    await refresh();
  }

  Future<void> update(AppTransaction tx) async {
    if (tx.id == null) return;
    await _db.updateTransaction(tx.id!, tx.toMap());
    await refresh();
  }

  Future<void> remove(int id) async {
    await _db.deleteTransaction(id);
    await refresh();
  }
}


