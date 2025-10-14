import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/db_helper.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  AppUser? _currentUser;
  bool _loading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> bootstrap() async {
    final userId = await _db.getCurrentUserId();
    if (userId == null) return;
    // Minimal lookup of user by id
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (rows.isNotEmpty) {
      _currentUser = AppUser.fromMap(rows.first);
      notifyListeners();
    }
  }

  String _hashPassword(String raw) {
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> signup(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final passwordHash = _hashPassword(password);
      final id = await _db.createUser(username: username, passwordHash: passwordHash);
      _currentUser = AppUser(id: id, username: username, passwordHash: passwordHash, createdAt: DateTime.now().millisecondsSinceEpoch);
      await _db.setCurrentUserId(id);
      await _applyOnboardingDataIfAny(userId: id);
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _applyOnboardingDataIfAny({required int userId}) async {
    final jsonStr = await _db.getPreference('onboarding_data');
    if (jsonStr == null || jsonStr.isEmpty) return;
    try {
      final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
      final monthlyIncome = (data['monthlyIncome'] as num?)?.toDouble() ?? 0;
      final budgets = (data['budgets'] as Map?)?.cast<String, dynamic>() ?? {};
      final goal = (data['goal'] as Map?)?.cast<String, dynamic>() ?? {};

      // Insert budgets
      for (final entry in budgets.entries) {
        final name = entry.key;
        final amount = (entry.value as num?)?.toDouble() ?? 0;
        if (amount <= 0) continue;
        await _db.insertBudget({
          'name': name,
          'category': name,
          'amount': amount,
          'icon': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Insert income transaction to record baseline cash-in
      if (monthlyIncome > 0) {
        await _db.insertTransaction({
          'user_id': userId,
          'type': 'income',
          'amount': monthlyIncome,
          'category': 'Onboarding',
          'note': 'Initial monthly income',
          'date': DateTime.now().millisecondsSinceEpoch,
          'budget_id': null,
          'goal_id': null,
        });
      }

      // Insert first goal
      final goalName = (goal['name'] as String?)?.trim();
      final goalTarget = (goal['target'] as num?)?.toDouble() ?? 0;
      if (goalName != null && goalName.isNotEmpty && goalTarget > 0) {
        await _db.insertGoal({
          'name': goalName,
          'target_amount': goalTarget,
          'saved_amount': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Clear onboarding snapshot after applying
      await _db.setPreference('onboarding_data', '');
    } catch (_) {
      // ignore parsing errors silently
    }
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final userRow = await _db.getUserByUsername(username);
      if (userRow == null) {
        _error = 'User not found';
        return false;
      }
      final hash = _hashPassword(password);
      if (userRow['password_hash'] != hash) {
        _error = 'Invalid credentials';
        return false;
      }
      final user = AppUser.fromMap(userRow);
      _currentUser = user;
      await _db.setCurrentUserId(user.id);
      return true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _db.setCurrentUserId(null);
    _currentUser = null;
    notifyListeners();
  }
}


