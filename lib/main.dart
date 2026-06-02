import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/app_state.dart';
import 'package:expense_tracker/providers/finance_provider.dart';
import 'package:expense_tracker/views/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isFirebaseConfigured = false;
  try {
    // Attempt Firebase Core initialization.
    // If config files (google-services.json / plist) are missing or invalid,
    // this will throw, which we catch to run in Local Sandbox Mode safely.
    await Firebase.initializeApp();
    isFirebaseConfigured = true;
  } catch (e) {
    debugPrint("-----------------------------------------------------------------");
    debugPrint("Firebase core initialization skipped/failed: $e");
    debugPrint("Running application in local offline SharedPreferences Sandbox mode.");
    debugPrint("To run cloud sync: add google-services.json or plist from Firebase Console.");
    debugPrint("-----------------------------------------------------------------");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(isFirebaseConfigured: isFirebaseConfigured),
        ),
        ChangeNotifierProxyProvider<AppState, FinanceProvider>(
          create: (_) => FinanceProvider(),
          update: (_, appState, finance) {
            finance!.update(
              appState.currentUserId,
              appState.transactionRepo,
              appState.budgetRepo,
              appState.goalRepo,
              appState.notificationRepo,
            );
            return finance;
          },
        ),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: appState.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
