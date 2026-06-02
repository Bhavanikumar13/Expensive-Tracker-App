import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/savings_goal.dart';
import 'package:expense_tracker/models/notification_alert.dart';

abstract class AuthRepository {
  Future<bool> signIn(String email, String password);
  Future<bool> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<String?> getCurrentUserId();
  Future<String?> getCurrentUserName();
  Stream<String?> get onAuthStateChanged;
}

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions(String userId);
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String transactionId, String userId);
}

abstract class BudgetRepository {
  Future<List<BudgetModel>> getBudgets(String userId);
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String budgetId, String userId);
}

abstract class GoalRepository {
  Future<List<SavingsGoalModel>> getGoals(String userId);
  Future<void> saveGoal(SavingsGoalModel goal);
  Future<void> deleteGoal(String goalId, String userId);
}

abstract class NotificationRepository {
  Future<List<NotificationAlertModel>> getNotifications(String userId);
  Future<void> addNotification(NotificationAlertModel notification);
  Future<void> markAsRead(String notificationId, String userId);
  Future<void> clearAll(String userId);
}
