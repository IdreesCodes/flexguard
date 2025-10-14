import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../utils/db_helper.dart';

class BudgetsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  final List<Budget> _budgets = [];
  bool _loading = false;

  List<Budget> get budgets => List.unmodifiable(_budgets);
  bool get isLoading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final rows = await _db.getBudgets();
      _budgets
        ..clear()
        ..addAll(rows.map(Budget.fromMap));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<double> spentFor(int budgetId) => _db.getBudgetSpent(budgetId);

  Future<void> add(Budget b) async {
    await _db.insertBudget(b.toMap());
    await refresh();
  }

  Future<void> update(Budget b) async {
    if (b.id == null) return;
    await _db.updateBudget(b.id!, b.toMap());
    await refresh();
  }

  Future<void> remove(int id) async {
    await _db.deleteBudget(id);
    await refresh();
  }
}


