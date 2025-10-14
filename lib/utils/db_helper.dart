import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'flex_guard.db';
  static const _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');

    // session (single row with current user id)
    await db.execute('''
      CREATE TABLE session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        current_user_id INTEGER,
        FOREIGN KEY(current_user_id) REFERENCES users(id) ON DELETE SET NULL
      );
    ''');
    await db.insert('session', {'id': 1, 'current_user_id': null});

    // preferences (key-value)
    await db.execute('''
      CREATE TABLE preferences (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    // budgets
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        icon TEXT,
        created_at INTEGER NOT NULL
      );
    ''');

    // goals
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    // transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT,
        note TEXT,
        date INTEGER NOT NULL,
        budget_id INTEGER,
        goal_id INTEGER,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(budget_id) REFERENCES budgets(id) ON DELETE SET NULL,
        FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE SET NULL
      );
    ''');

    // emotions (user mood around spending)
    await db.execute('''
      CREATE TABLE emotions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        transaction_id INTEGER,
        emotion TEXT NOT NULL,
        intensity INTEGER NOT NULL,
        note TEXT,
        trigger TEXT,
        date INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
      );
    ''');

    // upcoming payments (future obligations)
    await db.execute('''
      CREATE TABLE upcoming_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date INTEGER NOT NULL,
        category TEXT,
        recurring TEXT, -- none, monthly, yearly
        created_at INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');

    // challenges (local-only social-like savings challenges)
    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        deadline INTEGER,
        created_at INTEGER NOT NULL
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS emotions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          transaction_id INTEGER,
          emotion TEXT NOT NULL,
          intensity INTEGER NOT NULL,
          note TEXT,
          trigger TEXT,
          date INTEGER NOT NULL,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS upcoming_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          due_date INTEGER NOT NULL,
          category TEXT,
          recurring TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS challenges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          saved_amount REAL NOT NULL DEFAULT 0,
          deadline INTEGER,
          created_at INTEGER NOT NULL
        );
      ''');
    }
    if (oldVersion < 3) {
      // Add trigger column to existing emotions
      final cols = await db.rawQuery("PRAGMA table_info(emotions)");
      final hasTrigger = cols.any((c) => (c['name'] as String?) == 'trigger');
      if (!hasTrigger) {
        await db.execute('ALTER TABLE emotions ADD COLUMN trigger TEXT');
      }
    }
  }

  // ========== Users ==========
  Future<int> createUser({required String username, required String passwordHash}) async {
    final db = await database;
    return await db.insert('users', {
      'username': username,
      'password_hash': passwordHash,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, Object?>?> getUserByUsername(String username) async {
    final db = await database;
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // ========== Transactions ==========
  Future<int> insertTransaction(Map<String, Object?> values) async {
    final db = await database;
    return await db.insert('transactions', values);
  }

  Future<int> updateTransaction(int id, Map<String, Object?> values) async {
    final db = await database;
    return await db.update('transactions', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getRecentTransactions({required int userId, int limit = 3}) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, Object?>>> getTransactionsPaged({
    required int userId,
    required int offset,
    int limit = 20,
  }) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<double> getBalance({required int userId}) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type IN ('expense','savings') THEN amount ELSE 0 END), 0) AS outgo
      FROM transactions WHERE user_id = ?
    ''', [userId]);
    if (res.isEmpty) return 0;
    final row = res.first;
    final income = (row['income'] as num?)?.toDouble() ?? 0;
    final outgo = (row['outgo'] as num?)?.toDouble() ?? 0;
    return income - outgo;
  }

  Future<List<Map<String, Object?>>> getLast7DaysSpending({required int userId, required int nowMillis}) async {
    final db = await database;
    final sevenDaysAgo = nowMillis - 6 * 24 * 60 * 60 * 1000;
    // Group by day (UTC) for expenses only
    return await db.rawQuery('''
      SELECT 
        date((date/1000), 'unixepoch') as day,
        COALESCE(SUM(amount),0) as total
      FROM transactions
      WHERE user_id = ? AND type = 'expense' AND date BETWEEN ? AND ?
      GROUP BY day
      ORDER BY day ASC
    ''', [userId, sevenDaysAgo, nowMillis]);
  }

  Future<List<Map<String, Object?>>> getExpensesSince({required int userId, required int sinceMillis}) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'user_id = ? AND type = ? AND date >= ?',
      whereArgs: [userId, 'expense', sinceMillis],
      orderBy: 'date DESC',
    );
  }

  Future<Map<String, double>> getTotalsForRange({required int userId, required int startMillis, required int endMillis}) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
      FROM transactions WHERE user_id = ? AND date BETWEEN ? AND ?
    ''', [userId, startMillis, endMillis]);
    if (res.isEmpty) return {'income': 0.0, 'expense': 0.0};
    final row = res.first;
    return {
      'income': (row['income'] as num?)?.toDouble() ?? 0.0,
      'expense': (row['expense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // ========== Budgets ==========
  Future<int> insertBudget(Map<String, Object?> values) async {
    final db = await database;
    return await db.insert('budgets', values);
  }

  Future<int> updateBudget(int id, Map<String, Object?> values) async {
    final db = await database;
    return await db.update('budgets', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getBudgets() async {
    final db = await database;
    return await db.query('budgets', orderBy: 'created_at DESC');
  }

  Future<double> getBudgetSpent(int budgetId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT COALESCE(SUM(amount),0) as spent FROM transactions WHERE budget_id = ? AND type = 'expense'
    ''', [budgetId]);
    if (res.isEmpty) return 0;
    return (res.first['spent'] as num).toDouble();
  }

  Future<Map<String, Object?>?> getBudgetByCategory(String category) async {
    final db = await database;
    final rows = await db.query(
      'budgets',
      where: 'LOWER(category) = LOWER(?)',
      whereArgs: [category],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // ========== Goals ==========
  Future<int> insertGoal(Map<String, Object?> values) async {
    final db = await database;
    return await db.insert('goals', values);
  }

  Future<int> updateGoal(int id, Map<String, Object?> values) async {
    final db = await database;
    return await db.update('goals', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getGoals() async {
    final db = await database;
    return await db.query('goals', orderBy: 'created_at DESC');
  }

  // Preferences helpers
  Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.insert('preferences', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getPreference(String key) async {
    final db = await database;
    final res = await db.query('preferences', where: 'key = ?', whereArgs: [key], limit: 1);
    if (res.isEmpty) return null;
    return res.first['value'] as String?;
  }

  // Session helpers
  Future<void> setCurrentUserId(int? userId) async {
    final db = await database;
    await db.update('session', {'current_user_id': userId}, where: 'id = 1');
  }

  Future<int?> getCurrentUserId() async {
    final db = await database;
    final res = await db.query('session', where: 'id = 1', limit: 1);
    if (res.isEmpty) return null;
    return res.first['current_user_id'] as int?;
  }
}


