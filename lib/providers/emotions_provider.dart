import 'package:flutter/foundation.dart';
import '../models/emotion.dart';
import '../utils/db_helper.dart';

class EmotionsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final int userId;

  EmotionsProvider({required this.userId});

  final List<EmotionLog> _logs = [];
  bool _loading = false;

  List<EmotionLog> get logs => List.unmodifiable(_logs);
  bool get isLoading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      final rows = await db.query('emotions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
      _logs
        ..clear()
        ..addAll(rows.map(EmotionLog.fromMap));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(EmotionLog log) async {
    final db = await _db.database;
    await db.insert('emotions', log.toMap());
    await refresh();
  }
}


