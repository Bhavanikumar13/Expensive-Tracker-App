import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/data_repository.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/savings_goal.dart';
import 'package:expense_tracker/models/notification_alert.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  @override
  Stream<String?> get onAuthStateChanged => _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  @override
  Future<String?> getCurrentUserName() async {
    return _auth.currentUser?.displayName;
  }

  @override
  Future<bool> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user != null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        // Also save user profile to Firestore
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

class FirebaseTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final snapshot = await _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // overwrite or ensure correct id
      return TransactionModel.fromMap(data);
    }).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final docRef = _db.collection('transactions').doc(transaction.id.isEmpty ? null : transaction.id);
    final txMap = transaction.toMap();
    txMap['id'] = docRef.id;
    await docRef.set(txMap);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _db.collection('transactions').doc(transaction.id).update(transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String transactionId, String userId) async {
    await _db.collection('transactions').doc(transactionId).delete();
  }
}

class FirebaseBudgetRepository implements BudgetRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<BudgetModel>> getBudgets(String userId) async {
    final snapshot = await _db.collection('budgets').where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return BudgetModel.fromMap(data);
    }).toList();
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    // Check if category budget already exists for that month
    final snapshot = await _db
        .collection('budgets')
        .where('userId', isEqualTo: budget.userId)
        .where('category', isEqualTo: budget.category)
        .where('monthYear', isEqualTo: budget.monthYear)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // update
      final docId = snapshot.docs.first.id;
      await _db.collection('budgets').doc(docId).update(budget.toMap());
    } else {
      // create
      final docRef = _db.collection('budgets').doc(budget.id.isEmpty ? null : budget.id);
      final budgetMap = budget.toMap();
      budgetMap['id'] = docRef.id;
      await docRef.set(budgetMap);
    }
  }

  @override
  Future<void> deleteBudget(String budgetId, String userId) async {
    await _db.collection('budgets').doc(budgetId).delete();
  }
}

class FirebaseGoalRepository implements GoalRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<SavingsGoalModel>> getGoals(String userId) async {
    final snapshot = await _db.collection('savings_goals').where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SavingsGoalModel.fromMap(data);
    }).toList();
  }

  @override
  Future<void> saveGoal(SavingsGoalModel goal) async {
    final docRef = _db.collection('savings_goals').doc(goal.id.isEmpty ? null : goal.id);
    final goalMap = goal.toMap();
    goalMap['id'] = docRef.id;
    await docRef.set(goalMap);
  }

  @override
  Future<void> deleteGoal(String goalId, String userId) async {
    await _db.collection('savings_goals').doc(goalId).delete();
  }
}

class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<NotificationAlertModel>> getNotifications(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return NotificationAlertModel.fromMap(data);
    }).toList();
  }

  @override
  Future<void> addNotification(NotificationAlertModel notification) async {
    final docRef = _db.collection('notifications').doc(notification.id.isEmpty ? null : notification.id);
    final notificationMap = notification.toMap();
    notificationMap['id'] = docRef.id;
    await docRef.set(notificationMap);
  }

  @override
  Future<void> markAsRead(String notificationId, String userId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> clearAll(String userId) async {
    final snapshot = await _db.collection('notifications').where('userId', isEqualTo: userId).get();
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
