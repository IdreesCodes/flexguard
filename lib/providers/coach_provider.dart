import 'package:flutter/foundation.dart';
import '../utils/db_helper.dart';

class CoachProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final int userId;

  CoachProvider({required this.userId});

  final List<String> _tips = [];
  bool _loading = false;

  List<String> get tips => List.unmodifiable(_tips);
  bool get isLoading => _loading;

  Future<void> analyze() async {
    _loading = true;
    _tips.clear();
    notifyListeners();
    try {
      // Balance
      final balance = await _db.getBalance(userId: userId);
      if (balance < 0) {
        _tips.add('Your overall balance is negative. Consider pausing non-essential expenses this week.');
      } else if (balance < 100) {
        _tips.add('Your balance is low. Try a no-spend day to recover.');
      }

      // Budget stress: any budget spent > 80%
      final budgets = await _db.getBudgets();
      for (final b in budgets) {
        final id = b['id'] as int?;
        if (id == null) continue;
        final target = (b['amount'] as num).toDouble();
        final spent = await _db.getBudgetSpent(id);
        if (target > 0 && spent / target >= 0.8) {
          _tips.add('Budget "${b['name']}" is over 80% used. Tighten this category until reset.');
        }
      }

      // Upcoming payments within 7 days
      final db = await _db.database;
      final now = DateTime.now();
      final in7 = now.add(const Duration(days: 7)).millisecondsSinceEpoch;
      final rows = await db.query('upcoming_payments', where: 'user_id = ? AND due_date <= ?', whereArgs: [userId, in7]);
      if (rows.isNotEmpty) {
        _tips.add('You have ${rows.length} upcoming payment(s) in the next 7 days. Set aside funds now.');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}


