import 'package:flutter/foundation.dart';
import '../models/challenge.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/db_helper.dart';

class ChallengesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final int userId;

  ChallengesProvider({required this.userId});

  final List<Challenge> _items = [];
  bool _loading = false;

  List<Challenge> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      final rows = await db.query('challenges', orderBy: 'created_at DESC');
      _items
        ..clear()
        ..addAll(rows.map(Challenge.fromMap));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(Challenge c) async {
    final db = await _db.database;
    await db.insert('challenges', c.toMap());
    await refresh();
  }

  Future<void> contribute(Challenge c, double amount) async {
    if (amount <= 0 || c.id == null) return;
    final db = await _db.database;
    final updated = c.savedAmount + amount;
    await db.update('challenges', {'saved_amount': updated}, where: 'id = ?', whereArgs: [c.id]);
    // Record a savings transaction for traceability
    await _db.insertTransaction(AppTransaction(
      userId: userId,
      type: TransactionType.savings,
      amount: amount,
      category: 'Challenge',
      note: 'Contributed to ${c.name}',
      date: DateTime.now().millisecondsSinceEpoch,
    ).toMap());
    await refresh();
  }
}


