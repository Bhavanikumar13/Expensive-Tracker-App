import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/data_repository.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/savings_goal.dart';
import 'package:expense_tracker/models/notification_alert.dart';

class FinanceProvider extends ChangeNotifier {
  String? _userId;
  TransactionRepository? _txRepo;
  BudgetRepository? _budgetRepo;
  GoalRepository? _goalRepo;
  NotificationRepository? _notificationRepo;

  final _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<SavingsGoalModel> _goals = [];
  List<NotificationAlertModel> _notifications = [];

  bool _isFetching = false;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  List<SavingsGoalModel> get goals => _goals;
  List<NotificationAlertModel> get notifications => _notifications;
  bool get isFetching => _isFetching;

  // Quick Stats
  double get totalIncome => _transactions.where((t) => t.isIncome).fold(0.0, (sum, item) => sum + item.amount);
  double get totalExpenses => _transactions.where((t) => !t.isIncome).fold(0.0, (sum, item) => sum + item.amount);
  double get currentBalance => totalIncome - totalExpenses;

  // Current Month Stats (Utility helper for Dashboard)
  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.isIncome && t.dateTime.year == now.year && t.dateTime.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthlyExpenses {
    final now = DateTime.now();
    return _transactions
        .where((t) => !t.isIncome && t.dateTime.year == now.year && t.dateTime.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Update repository references when AppState changes
  void update(
    String? userId,
    TransactionRepository txRepo,
    BudgetRepository budgetRepo,
    GoalRepository goalRepo,
    NotificationRepository notificationRepo,
  ) {
    final userChanged = _userId != userId;
    _userId = userId;
    _txRepo = txRepo;
    _budgetRepo = budgetRepo;
    _goalRepo = goalRepo;
    _notificationRepo = notificationRepo;

    if (userChanged) {
      if (userId != null) {
        loadAllData();
      } else {
        _clearLocalCache();
      }
    }
  }

  void _clearLocalCache() {
    _transactions = [];
    _budgets = [];
    _goals = [];
    _notifications = [];
    notifyListeners();
  }

  Future<void> loadAllData() async {
    final uid = _userId;
    if (uid == null) return;

    _isFetching = true;
    notifyListeners();

    try {
      _transactions = await _txRepo!.getTransactions(uid);
      _budgets = await _budgetRepo!.getBudgets(uid);
      _goals = await _goalRepo!.getGoals(uid);
      _notifications = await _notificationRepo!.getNotifications(uid);
    } catch (e) {
      debugPrint("Error loading finance data: $e");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  // Seed default data for Demo Mode
  Future<void> seedDemoData() async {
    final uid = _userId;
    if (uid == null) return;

    _isFetching = true;
    notifyListeners();

    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(now);

    final demoTransactions = [
      TransactionModel(
        id: _uuid.v4(),
        title: 'Monthly Salary',
        amount: 85000,
        category: 'Salary',
        dateTime: now.subtract(const Duration(days: 15)),
        isIncome: true,
        notes: 'Tech Corp monthly payroll',
        userId: uid,
      ),
      TransactionModel(
        id: _uuid.v4(),
        title: 'Freelance Design',
        amount: 15000,
        category: 'Freelancing',
        dateTime: now.subtract(const Duration(days: 5)),
        isIncome: true,
        notes: 'Landing page mockup',
        userId: uid,
      ),
      TransactionModel(
        id: _uuid.v4(),
        title: 'Apartment Rent',
        amount: 18000,
        category: 'Rent',
        dateTime: now.subtract(const Duration(days: 14)),
        isIncome: false,
        notes: 'Monthly apartment cost',
        userId: uid,
      ),
      TransactionModel(
        id: _uuid.v4(),
        title: 'Groceries Store',
        amount: 4200,
        category: 'Food',
        dateTime: now.subtract(const Duration(days: 3)),
        isIncome: false,
        notes: 'Weekly whole food shopping',
        userId: uid,
      ),
      TransactionModel(
        id: _uuid.v4(),
        title: 'Electricity Bill',
        amount: 3100,
        category: 'Utilities',
        dateTime: now.subtract(const Duration(days: 10)),
        isIncome: false,
        userId: uid,
      ),
      TransactionModel(
        id: _uuid.v4(),
        title: 'Cinema Tickets',
        amount: 1200,
        category: 'Entertainment',
        dateTime: now.subtract(const Duration(days: 1)),
        isIncome: false,
        notes: 'Sci-fi movie night with friends',
        userId: uid,
      ),
      TransactionModel(
        id: _uuid.v4(),
        title: 'Gym Membership',
        amount: 2500,
        category: 'Healthcare',
        dateTime: now.subtract(const Duration(days: 12)),
        isIncome: false,
        userId: uid,
      ),
    ];

    final demoBudgets = [
      BudgetModel(
        id: _uuid.v4(),
        category: 'Food',
        limitAmount: 10000,
        monthYear: currentMonthStr,
        userId: uid,
      ),
      BudgetModel(
        id: _uuid.v4(),
        category: 'Entertainment',
        limitAmount: 5000,
        monthYear: currentMonthStr,
        userId: uid,
      ),
      BudgetModel(
        id: _uuid.v4(),
        category: 'Rent',
        limitAmount: 20000,
        monthYear: currentMonthStr,
        userId: uid,
      ),
      BudgetModel(
        id: _uuid.v4(),
        category: 'Utilities',
        limitAmount: 6000,
        monthYear: currentMonthStr,
        userId: uid,
      ),
    ];

    final demoGoals = [
      SavingsGoalModel(
        id: _uuid.v4(),
        title: 'Buy Laptop',
        targetAmount: 60000,
        currentAmount: 40000,
        targetDate: now.add(const Duration(days: 90)),
        userId: uid,
      ),
      SavingsGoalModel(
        id: _uuid.v4(),
        title: 'Emergency Fund',
        targetAmount: 150000,
        currentAmount: 85000,
        targetDate: now.add(const Duration(days: 365)),
        userId: uid,
      ),
    ];

    final demoNotifications = [
      NotificationAlertModel(
        id: _uuid.v4(),
        title: 'Welcome!',
        message: 'Welcome to your Smart Expense Tracker. Seeding demo records.',
        dateTime: now,
        userId: uid,
        isRead: false,
      )
    ];

    try {
      for (var tx in demoTransactions) {
        await _txRepo!.addTransaction(tx);
      }
      for (var b in demoBudgets) {
        await _budgetRepo!.saveBudget(b);
      }
      for (var g in demoGoals) {
        await _goalRepo!.saveGoal(g);
      }
      for (var n in demoNotifications) {
        await _notificationRepo!.addNotification(n);
      }
      await loadAllData();
    } catch (e) {
      debugPrint("Error seeding data: $e");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  // Smart Category Predictor
  String predictCategory(String title, bool isIncome) {
    final query = title.toLowerCase().trim();
    if (isIncome) {
      if (query.contains('salary') || query.contains('paycheck') || query.contains('payroll') || query.contains('job')) {
        return 'Salary';
      }
      if (query.contains('freelance') || query.contains('upwork') || query.contains('contract') || query.contains('client')) {
        return 'Freelancing';
      }
      if (query.contains('business') || query.contains('sale') || query.contains('shop') || query.contains('revenue')) {
        return 'Business';
      }
      if (query.contains('invest') || query.contains('dividend') || query.contains('stock') || query.contains('crypto') || query.contains('interest')) {
        return 'Investments';
      }
      if (query.contains('scholar') || query.contains('grant') || query.contains('stipend')) {
        return 'Scholarships';
      }
      return 'Other Income';
    } else {
      if (query.contains('food') || query.contains('restaurant') || query.contains('mcdonald') || query.contains('grocery') || query.contains('groceries') || query.contains('cafe') || query.contains('dinner') || query.contains('lunch') || query.contains('starbucks') || query.contains('swiggy') || query.contains('zomato')) {
        return 'Food';
      }
      if (query.contains('uber') || query.contains('ola') || query.contains('taxi') || query.contains('metro') || query.contains('bus') || query.contains('train') || query.contains('flight') || query.contains('gas') || query.contains('petrol') || query.contains('fuel') || query.contains('car')) {
        return 'Transportation';
      }
      if (query.contains('book') || query.contains('course') || query.contains('tuition') || query.contains('school') || query.contains('college') || query.contains('udemy') || query.contains('exam')) {
        return 'Education';
      }
      if (query.contains('netflix') || query.contains('spotify') || query.contains('movie') || query.contains('cinema') || query.contains('game') || query.contains('theater') || query.contains('concert') || query.contains('show')) {
        return 'Entertainment';
      }
      if (query.contains('doctor') || query.contains('medicine') || query.contains('pharmacy') || query.contains('hospital') || query.contains('health') || query.contains('gym') || query.contains('dentist')) {
        return 'Healthcare';
      }
      if (query.contains('clothes') || query.contains('shoes') || query.contains('amazon') || query.contains('flipkart') || query.contains('mall') || query.contains('shopping') || query.contains('store')) {
        return 'Shopping';
      }
      if (query.contains('electricity') || query.contains('water') || query.contains('gas bill') || query.contains('utility') || query.contains('wifi') || query.contains('internet') || query.contains('mobile recharge') || query.contains('phone bill')) {
        return 'Utilities';
      }
      if (query.contains('rent') || query.contains('hostel') || query.contains('pg fee') || query.contains('lease')) {
        return 'Rent';
      }
      return 'Food'; // Fallback default
    }
  }

  // --- Transactions Logic ---
  Future<void> addTransaction({
    required String title,
    required double amount,
    required String category,
    required DateTime dateTime,
    required bool isIncome,
    String notes = '',
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final tx = TransactionModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      category: category,
      dateTime: dateTime,
      isIncome: isIncome,
      notes: notes,
      userId: uid,
    );

    // Optimistic UI updates
    _transactions.insert(0, tx);
    notifyListeners();

    try {
      await _txRepo!.addTransaction(tx);
      // Run smart checking algorithms
      if (!isIncome) {
        await _checkBudgetAlerts(category, dateTime, amount);
        await _checkLargeExpenseAlert(title, amount);
      }
    } catch (e) {
      debugPrint("Error writing transaction: $e");
      // Rollback
      _transactions.removeWhere((item) => item.id == tx.id);
      notifyListeners();
    }
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final idx = _transactions.indexWhere((e) => e.id == tx.id);
    if (idx == -1) return;

    final originalTx = _transactions[idx];
    _transactions[idx] = tx;
    notifyListeners();

    try {
      await _txRepo!.updateTransaction(tx);
    } catch (e) {
      _transactions[idx] = originalTx;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final uid = _userId;
    if (uid == null) return;

    final idx = _transactions.indexWhere((e) => e.id == transactionId);
    if (idx == -1) return;

    final deletedTx = _transactions[idx];
    _transactions.removeAt(idx);
    notifyListeners();

    try {
      await _txRepo!.deleteTransaction(transactionId, uid);
    } catch (e) {
      _transactions.insert(idx, deletedTx);
      notifyListeners();
    }
  }

  // --- Budgets Logic ---
  Future<void> saveBudget(String category, double limitAmount, String monthYear) async {
    final uid = _userId;
    if (uid == null) return;

    final budget = BudgetModel(
      id: _uuid.v4(),
      category: category,
      limitAmount: limitAmount,
      monthYear: monthYear,
      userId: uid,
    );

    final idx = _budgets.indexWhere((e) => e.category == category && e.monthYear == monthYear);
    final isNew = idx == -1;
    final BudgetModel? oldBudget = isNew ? null : _budgets[idx];

    if (isNew) {
      _budgets.add(budget);
    } else {
      _budgets[idx] = budget;
    }
    notifyListeners();

    try {
      await _budgetRepo!.saveBudget(budget);
    } catch (e) {
      if (isNew) {
        _budgets.removeWhere((item) => item.category == category && item.monthYear == monthYear);
      } else {
        _budgets[idx] = oldBudget!;
      }
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String budgetId, String userId) async {
    final idx = _budgets.indexWhere((e) => e.id == budgetId);
    if (idx == -1) return;

    final deleted = _budgets[idx];
    _budgets.removeAt(idx);
    notifyListeners();

    try {
      await _budgetRepo!.deleteBudget(budgetId, userId);
    } catch (e) {
      _budgets.insert(idx, deleted);
      notifyListeners();
    }
  }

  double getSpentForCategory(String category, String monthYear) {
    return _transactions
        .where((t) =>
            !t.isIncome &&
            t.category == category &&
            DateFormat('yyyy-MM').format(t.dateTime) == monthYear)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  BudgetModel? getBudgetForCategory(String category, String monthYear) {
    try {
      return _budgets.firstWhere((b) => b.category == category && b.monthYear == monthYear);
    } catch (_) {
      return null;
    }
  }

  // --- Savings Goals Logic ---
  Future<void> saveGoal({
    required String title,
    required double targetAmount,
    required double currentAmount,
    required DateTime targetDate,
    String? id,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final goal = SavingsGoalModel(
      id: id ?? _uuid.v4(),
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
      userId: uid,
    );

    final idx = _goals.indexWhere((e) => e.id == goal.id);
    final isNew = idx == -1;
    final SavingsGoalModel? oldGoal = isNew ? null : _goals[idx];

    if (isNew) {
      _goals.add(goal);
    } else {
      _goals[idx] = goal;
    }
    notifyListeners();

    try {
      await _goalRepo!.saveGoal(goal);
      if (isNew) {
        await addNotification(
          'Goal Created!',
          'Start saving for your goal: "$title" (Target: ₹${NumberFormat('#,##,###').format(targetAmount)}).',
        );
      } else if (goal.isCompleted && (oldGoal == null || !oldGoal.isCompleted)) {
        await addNotification(
          'Savings Goal Achieved! 🎉',
          'Congratulations! You saved ₹${NumberFormat('#,##,###').format(targetAmount)} and accomplished your goal: "$title".',
        );
      }
    } catch (e) {
      if (isNew) {
        _goals.removeWhere((item) => item.id == goal.id);
      } else {
        _goals[idx] = oldGoal!;
      }
      notifyListeners();
    }
  }

  Future<void> contributeToGoal(String goalId, double amount) async {
    final idx = _goals.indexWhere((e) => e.id == goalId);
    if (idx == -1) return;

    final goal = _goals[idx];
    final updatedGoal = goal.copyWith(currentAmount: goal.currentAmount + amount);
    await saveGoal(
      title: updatedGoal.title,
      targetAmount: updatedGoal.targetAmount,
      currentAmount: updatedGoal.currentAmount,
      targetDate: updatedGoal.targetDate,
      id: updatedGoal.id,
    );

    // Automatically record an expense for the savings contribution
    await addTransaction(
      title: 'Savings Contribution: ${goal.title}',
      amount: amount,
      category: 'Rent', // Or generic custom, but let's associate with rent/saving context
      dateTime: DateTime.now(),
      isIncome: false,
      notes: 'Transferred to goal savings pot.',
    );
  }

  Future<void> deleteGoal(String goalId) async {
    final uid = _userId;
    if (uid == null) return;

    final idx = _goals.indexWhere((e) => e.id == goalId);
    if (idx == -1) return;

    final deleted = _goals[idx];
    _goals.removeAt(idx);
    notifyListeners();

    try {
      await _goalRepo!.deleteGoal(goalId, uid);
    } catch (e) {
      _goals.insert(idx, deleted);
      notifyListeners();
    }
  }

  // --- Notifications Alerts ---
  Future<void> addNotification(String title, String message) async {
    final uid = _userId;
    if (uid == null) return;

    final alert = NotificationAlertModel(
      id: _uuid.v4(),
      title: title,
      message: message,
      dateTime: DateTime.now(),
      isRead: false,
      userId: uid,
    );

    _notifications.insert(0, alert);
    notifyListeners();

    try {
      await _notificationRepo!.addNotification(alert);
    } catch (e) {
      _notifications.removeWhere((item) => item.id == alert.id);
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final uid = _userId;
    if (uid == null) return;

    final idx = _notifications.indexWhere((e) => e.id == notificationId);
    if (idx == -1) return;

    final alert = _notifications[idx];
    _notifications[idx] = alert.copyWith(isRead: true);
    notifyListeners();

    try {
      await _notificationRepo!.markAsRead(notificationId, uid);
    } catch (e) {
      _notifications[idx] = alert;
      notifyListeners();
    }
  }

  Future<void> clearAllNotifications() async {
    final uid = _userId;
    if (uid == null) return;

    final backup = List<NotificationAlertModel>.from(_notifications);
    _notifications = [];
    notifyListeners();

    try {
      await _notificationRepo!.clearAll(uid);
    } catch (e) {
      _notifications = backup;
      notifyListeners();
    }
  }

  // --- Alert Trigger Engines ---
  Future<void> _checkBudgetAlerts(String category, DateTime date, double addedAmount) async {
    final monthYear = DateFormat('yyyy-MM').format(date);
    final budget = getBudgetForCategory(category, monthYear);
    if (budget == null) return;

    final spentTotal = getSpentForCategory(category, monthYear);
    final limit = budget.limitAmount;
    final percent = (spentTotal / limit) * 100;

    final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    if (spentTotal >= limit) {
      await addNotification(
        '🔴 Budget Limit Exceeded!',
        'You have spent ${format.format(spentTotal)} of your ${format.format(limit)} budget limit for $category.',
      );
    } else if (percent >= 80 && (spentTotal - addedAmount) / limit < 0.80) {
      await addNotification(
        '⚠️ Budget Alert (80%+)',
        'You have spent ${format.format(spentTotal)} of your ${format.format(limit)} budget limit for $category.',
      );
    }
  }

  Future<void> _checkLargeExpenseAlert(String title, double amount) async {
    // Large expense trigger set to ₹10,000
    if (amount >= 10000) {
      final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);
      await addNotification(
        '💸 Large Expense Logged',
        'An expense of ${format.format(amount)} was logged for "$title". Please review your monthly budget.',
      );
    }
  }

  // --- CSV / Text summary report creators ---
  String generateTextReport(int year, int month) {
    final monthStr = DateFormat('yyyy-MM').format(DateTime(year, month));
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    final monthlyTxs = _transactions.where((t) => DateFormat('yyyy-MM').format(t.dateTime) == monthStr).toList();
    if (monthlyTxs.isEmpty) {
      return "No financial records found for $monthName.";
    }

    final income = monthlyTxs.where((t) => t.isIncome).fold(0.0, (sum, item) => sum + item.amount);
    final expense = monthlyTxs.where((t) => !t.isIncome).fold(0.0, (sum, item) => sum + item.amount);
    final net = income - expense;

    final Map<String, double> categorySums = {};
    for (var tx in monthlyTxs.where((t) => !t.isIncome)) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0.0) + tx.amount;
    }

    final sortedCategories = categorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final highestCategoryStr = sortedCategories.isNotEmpty
        ? "${sortedCategories.first.key}: ₹${NumberFormat('#,##,###').format(sortedCategories.first.value)}"
        : "None";

    final buffer = StringBuffer();
    buffer.writeln("=================================");
    buffer.writeln("  SMART EXPENSE REPORT - $monthName");
    buffer.writeln("=================================");
    buffer.writeln("Total Income:   ₹${NumberFormat('#,##,###').format(income)}");
    buffer.writeln("Total Expenses: ₹${NumberFormat('#,##,###').format(expense)}");
    buffer.writeln("Net Savings:    ₹${NumberFormat('#,##,###').format(net)}");
    buffer.writeln("Budget Status:  ${expense > income ? '⚠️ Deficit' : '✅ Surplus'}");
    buffer.writeln("---------------------------------");
    buffer.writeln("Highest Category Spending:");
    buffer.writeln("  $highestCategoryStr");
    buffer.writeln("---------------------------------");
    buffer.writeln("Category-wise Expense Breakdown:");
    for (var cat in sortedCategories) {
      buffer.writeln("  * ${cat.key.padRight(15)}: ₹${NumberFormat('#,##,###').format(cat.value)}");
    }
    buffer.writeln("---------------------------------");
    buffer.writeln("Budget Utilization Check:");
    final relevantBudgets = _budgets.where((b) => b.monthYear == monthStr).toList();
    if (relevantBudgets.isEmpty) {
      buffer.writeln("  No budgets configured for this month.");
    } else {
      for (var b in relevantBudgets) {
        final spent = getSpentForCategory(b.category, monthStr);
        final ratio = b.limitAmount > 0 ? (spent / b.limitAmount) * 100 : 0.0;
        buffer.writeln("  * ${b.category.padRight(12)}: Limit: ₹${NumberFormat('#,##,###').format(b.limitAmount)} | Spent: ₹${NumberFormat('#,##,###').format(spent)} (${ratio.toStringAsFixed(1)}%)");
      }
    }
    buffer.writeln("=================================");
    return buffer.toString();
  }

  String generateCsvReport(int year, int month) {
    final monthStr = DateFormat('yyyy-MM').format(DateTime(year, month));
    final monthlyTxs = _transactions.where((t) => DateFormat('yyyy-MM').format(t.dateTime) == monthStr).toList();

    if (monthlyTxs.isEmpty) return "No data";

    final csv = StringBuffer();
    csv.writeln("ID,Date,Title,Amount,Type,Category,Notes");
    for (var tx in monthlyTxs) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.dateTime);
      final type = tx.isIncome ? "Income" : "Expense";
      csv.writeln('"${tx.id}","${date}","${tx.title.replaceAll('"', '""')}",${tx.amount},"${type}","${tx.category}","${tx.notes.replaceAll('"', '""')}"');
    }
    return csv.toString();
  }
}
