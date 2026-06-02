import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/app_state.dart';
import 'package:expense_tracker/providers/finance_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final finance = Provider.of<FinanceProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User profile snippet
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  child: Icon(Icons.person_rounded, size: 36, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.currentUserName ?? 'Finance User',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.useFirebase ? 'Firebase Sync Connected' : 'Offline Sandbox Profile',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Database Configurations Section
          Text(
            'Database & Sync Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Column(
              children: [
                // Cloud Sync Switch
                SwitchListTile(
                  title: Text(
                    'Firebase Cloud Sync',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15),
                  ),
                  subtitle: Text(
                    appState.isFirebaseConfigured
                        ? 'Sync your balance & targets in real-time.'
                        : 'Unavailable: Firebase credentials not found in application bundle.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: appState.useFirebase,
                  activeColor: AppTheme.primary,
                  onChanged: appState.isFirebaseConfigured
                      ? (value) async {
                          try {
                            await appState.setUseFirebase(value);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value ? 'Switched to Firebase Mode' : 'Switched to Local Sandbox Mode'),
                                  backgroundColor: AppTheme.accentIncome,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.accentExpense),
                              );
                            }
                          }
                        }
                      : null,
                ),
                const Divider(),
                // Seed Sandbox Data
                ListTile(
                  leading: Icon(Icons.playlist_add_check_rounded, color: AppTheme.accentSavings),
                  title: Text('Seed Sandbox Data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  subtitle: const Text('Populates the database with demo transactions, budgets & goals.', style: TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                  onTap: () async {
                    await finance.seedDemoData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sandbox data loaded successfully! Go check your Dashboard.'),
                          backgroundColor: AppTheme.accentIncome,
                        ),
                      );
                      Navigator.pop(context); // Go back to shell
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Configurations Section
          Text(
            'Appearance Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: SwitchListTile(
              secondary: Icon(
                appState.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: appState.isDarkMode ? AppTheme.accentSavings : AppTheme.accentWarning,
              ),
              title: Text(
                'Light Theme Mode',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15),
              ),
              subtitle: const Text(
                'Toggle between sleek dark and premium light modes.',
                style: TextStyle(fontSize: 12),
              ),
              value: !appState.isDarkMode,
              activeColor: AppTheme.primary,
              onChanged: (value) {
                appState.setDarkMode(!value);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Security & Info Section
          Text(
            'Information & Security',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
                  title: Text('Encryption Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  subtitle: const Text('Transactions are AES-256 encrypted on local disk storage.', style: TextStyle(fontSize: 12)),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                  title: Text('App Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  subtitle: Text('v0.1.0-alpha (Build 2026.06)', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Sign Out Button
          ElevatedButton.icon(
            onPressed: () async {
              await appState.logout();
              if (context.mounted) {
                Navigator.pop(context); // Return out of Settings (auth listener will switch shell to Login)
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            label: const Text('Secure Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentExpense,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}