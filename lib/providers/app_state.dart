import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/data_repository.dart';
import 'package:expense_tracker/core/local_repository.dart';
import 'package:expense_tracker/core/firebase_repository.dart';
import 'package:expense_tracker/core/theme.dart';

class AppState extends ChangeNotifier {
  final bool isFirebaseConfigured;
  
  bool _useFirebase = false;
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentUserName;
  StreamSubscription<String?>? _authSubscription;
  bool _isDarkMode = true;

  // Local Repository Instances
  final LocalAuthRepository _localAuth = LocalAuthRepository();
  final LocalTransactionRepository _localTx = LocalTransactionRepository();
  final LocalBudgetRepository _localBudget = LocalBudgetRepository();
  final LocalGoalRepository _localGoal = LocalGoalRepository();
  final LocalNotificationRepository _localNotification = LocalNotificationRepository();

  // Firebase Repository Instances (Lazy instantiated only if configured)
  FirebaseAuthRepository? _firebaseAuth;
  FirebaseTransactionRepository? _firebaseTx;
  FirebaseBudgetRepository? _firebaseBudget;
  FirebaseGoalRepository? _firebaseGoal;
  FirebaseNotificationRepository? _firebaseNotification;

  AppState({required this.isFirebaseConfigured}) {
    _loadSyncPreference();
  }

  // Getters
  bool get useFirebase => _useFirebase && isFirebaseConfigured;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  bool get isAuthenticated => _currentUserId != null;
  bool get isDarkMode => _isDarkMode;

  // Repository Getters (Dynamic selection)
  AuthRepository get authRepo => useFirebase ? (_firebaseAuth ??= FirebaseAuthRepository()) : _localAuth;
  TransactionRepository get transactionRepo => useFirebase ? (_firebaseTx ??= FirebaseTransactionRepository()) : _localTx;
  BudgetRepository get budgetRepo => useFirebase ? (_firebaseBudget ??= FirebaseBudgetRepository()) : _localBudget;
  GoalRepository get goalRepo => useFirebase ? (_firebaseGoal ??= FirebaseGoalRepository()) : _localGoal;
  NotificationRepository get notificationRepo => useFirebase ? (_firebaseNotification ??= FirebaseNotificationRepository()) : _localNotification;

  Future<void> _loadSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false (Local mode)
    _useFirebase = prefs.getBool('use_firebase_sync') ?? false;
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    AppTheme.configureTheme(_isDarkMode);
    await _setupAuthListener();
  }

  Future<void> setDarkMode(bool val) async {
    _isDarkMode = val;
    AppTheme.configureTheme(val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
    notifyListeners();
  }

  Future<void> setUseFirebase(bool value) async {
    if (value && !isFirebaseConfigured) {
      throw Exception('Firebase is not configured in this app environment.');
    }
    _useFirebase = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_firebase_sync', value);
    
    // Reset state & re-setup auth listener for the new repository
    _currentUserId = null;
    _currentUserName = null;
    await _setupAuthListener();
    notifyListeners();
  }

  Future<void> _setupAuthListener() async {
    await _authSubscription?.cancel();
    
    // Get initial user immediately
    _currentUserId = await authRepo.getCurrentUserId();
    _currentUserName = await authRepo.getCurrentUserName();
    notifyListeners();

    // Listen for changes
    _authSubscription = authRepo.onAuthStateChanged.listen((userId) async {
      _currentUserId = userId;
      if (userId != null) {
        _currentUserName = await authRepo.getCurrentUserName();
      } else {
        _currentUserName = null;
      }
      notifyListeners();
    });
  }

  // Authentication Wrapper Functions
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final success = await authRepo.signIn(email, password);
      _setLoading(false);
      return success;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      final success = await authRepo.signUp(email, password, name);
      _setLoading(false);
      return success;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await authRepo.signOut();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await authRepo.resetPassword(email);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
