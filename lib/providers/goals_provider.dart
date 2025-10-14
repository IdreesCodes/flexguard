import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/db_helper.dart';

class GoalsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  final List<Goal> _goals = [];
  bool _loading = false;

  List<Goal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final rows = await _db.getGoals();
      _goals
        ..clear()
        ..addAll(rows.map(Goal.fromMap));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(Goal g) async {
    await _db.insertGoal(g.toMap());
    await refresh();
  }

  Future<void> update(Goal g) async {
    if (g.id == null) return;
    await _db.updateGoal(g.id!, g.toMap());
    await refresh();
  }

  Future<void> remove(int id) async {
    await _db.deleteGoal(id);
    await refresh();
  }

  Future<void> addFunds({required int userId, required Goal goal, required double amount}) async {
    if (amount <= 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    // 1) Update goal saved amount
    final updated = goal.copyWith(savedAmount: goal.savedAmount + amount, updatedAt: now);
    if (goal.id != null) {
      await _db.updateGoal(goal.id!, updated.toMap());
    }
    // 2) Insert a corresponding savings transaction
    await _db.insertTransaction(AppTransaction(
      userId: userId,
      type: TransactionType.savings,
      amount: amount,
      category: 'Savings',
      note: 'Added to goal: ${goal.name}',
      date: now,
      goalId: goal.id,
    ).toMap());
    await refresh();
  }
}


