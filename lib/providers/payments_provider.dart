import 'package:flutter/foundation.dart';
import '../models/upcoming_payment.dart';
import '../utils/db_helper.dart';

class PaymentsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final int userId;

  PaymentsProvider({required this.userId});

  final List<UpcomingPayment> _items = [];
  bool _loading = false;

  List<UpcomingPayment> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      final rows = await db.query('upcoming_payments', where: 'user_id = ?', whereArgs: [userId], orderBy: 'due_date ASC');
      _items
        ..clear()
        ..addAll(rows.map(UpcomingPayment.fromMap));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(UpcomingPayment p) async {
    final db = await _db.database;
    await db.insert('upcoming_payments', p.toMap());
    await refresh();
  }

  Future<void> remove(int id) async {
    final db = await _db.database;
    await db.delete('upcoming_payments', where: 'id = ?', whereArgs: [id]);
    await refresh();
  }
}


