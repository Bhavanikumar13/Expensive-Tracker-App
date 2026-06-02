import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/data_repository.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/savings_goal.dart';
import 'package:expense_tracker/models/notification_alert.dart';

class LocalAuthRepository implements AuthRepository {
  final _authStreamController = StreamController<String?>.broadcast();
  static const String _usersKey = 'local_users_list';
  static const String _currentUserIdKey = 'local_current_user_id';
  static const String _currentUserNameKey = 'local_current_user_name';

  LocalAuthRepository() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final currentId = prefs.getString(_currentUserIdKey);
    _authStreamController.add(currentId);
  }

  @override
  Stream<String?> get onAuthStateChanged => _authStreamController.stream;

  @override
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey);
  }

  @override
  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserNameKey);
  }

  @override
  Future<bool> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '[]';
    final List<dynamic> usersList = jsonDecode(usersJson);

    for (var u in usersList) {
      if (u['email'] == email && u['password'] == password) {
        await prefs.setString(_currentUserIdKey, u['id']);
        await prefs.setString(_currentUserNameKey, u['name']);
        _authStreamController.add(u['id']);
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> signUp(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '[]';
    final List<dynamic> usersList = List.from(jsonDecode(usersJson));

    // Check if user already exists
    for (var u in usersList) {
      if (u['email'] == email) {
        return false;
      }
    }

    final newId = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final newUser = {
      'id': newId,
      'email': email,
      'password': password,
      'name': name,
    };
    usersList.add(newUser);

    await prefs.setString(_usersKey, jsonEncode(usersList));
    await prefs.setString(_currentUserIdKey, newId);
    await prefs.setString(_currentUserNameKey, name);
    _authStreamController.add(newId);
    return true;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    await prefs.remove(_currentUserNameKey);
    _authStreamController.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {
    // For local mock: check if user exists
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '[]';
    final List<dynamic> usersList = jsonDecode(usersJson);
    final exists = usersList.any((u) => u['email'] == email);
    if (!exists) {
      throw Exception('User email not found in local records.');
    }
  }
}

class LocalTransactionRepository implements TransactionRepository {
  String _key(String userId) => 'local_transactions_$userId';

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key(userId)) ?? '[]';
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((item) => TransactionModel.fromMap(item)).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final txs = await getTransactions(transaction.userId);
    txs.add(transaction);
    await prefs.setString(_key(transaction.userId), jsonEncode(txs.map((e) => e.toMap()).toList()));
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final txs = await getTransactions(transaction.userId);
    final idx = txs.indexWhere((e) => e.id == transaction.id);
    if (idx != -1) {
      txs[idx] = transaction;
      await prefs.setString(_key(transaction.userId), jsonEncode(txs.map((e) => e.toMap()).toList()));
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final txs = await getTransactions(userId);
    txs.removeWhere((e) => e.id == transactionId);
    await prefs.setString(_key(userId), jsonEncode(txs.map((e) => e.toMap()).toList()));
  }
}

class LocalBudgetRepository implements BudgetRepository {
  String _key(String userId) => 'local_budgets_$userId';

  @override
  Future<List<BudgetModel>> getBudgets(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key(userId)) ?? '[]';
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((item) => BudgetModel.fromMap(item)).toList();
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = await getBudgets(budget.userId);
    final idx = budgets.indexWhere((e) => e.category == budget.category && e.monthYear == budget.monthYear);
    if (idx != -1) {
      budgets[idx] = budget;
    } else {
      budgets.add(budget);
    }
    await prefs.setString(_key(budget.userId), jsonEncode(budgets.map((e) => e.toMap()).toList()));
  }

  @override
  Future<void> deleteBudget(String budgetId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = await getBudgets(userId);
    budgets.removeWhere((e) => e.id == budgetId);
    await prefs.setString(_key(userId), jsonEncode(budgets.map((e) => e.toMap()).toList()));
  }
}

class LocalGoalRepository implements GoalRepository {
  String _key(String userId) => 'local_goals_$userId';

  @override
  Future<List<SavingsGoalModel>> getGoals(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key(userId)) ?? '[]';
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((item) => SavingsGoalModel.fromMap(item)).toList();
  }

  @override
  Future<void> saveGoal(SavingsGoalModel goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals(goal.userId);
    final idx = goals.indexWhere((e) => e.id == goal.id);
    if (idx != -1) {
      goals[idx] = goal;
    } else {
      goals.add(goal);
    }
    await prefs.setString(_key(goal.userId), jsonEncode(goals.map((e) => e.toMap()).toList()));
  }

  @override
  Future<void> deleteGoal(String goalId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals(userId);
    goals.removeWhere((e) => e.id == goalId);
    await prefs.setString(_key(userId), jsonEncode(goals.map((e) => e.toMap()).toList()));
  }
}

class LocalNotificationRepository implements NotificationRepository {
  String _key(String userId) => 'local_notifications_$userId';

  @override
  Future<List<NotificationAlertModel>> getNotifications(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key(userId)) ?? '[]';
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((item) => NotificationAlertModel.fromMap(item)).toList();
  }

  @override
  Future<void> addNotification(NotificationAlertModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getNotifications(notification.userId);
    list.insert(0, notification); // Newest notifications at the top
    await prefs.setString(_key(notification.userId), jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  @override
  Future<void> markAsRead(String notificationId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getNotifications(userId);
    final idx = list.indexWhere((e) => e.id == notificationId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isRead: true);
      await prefs.setString(_key(userId), jsonEncode(list.map((e) => e.toMap()).toList()));
    }
  }

  @override
  Future<void> clearAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
