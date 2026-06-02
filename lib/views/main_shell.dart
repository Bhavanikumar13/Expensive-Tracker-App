import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/finance_provider.dart';
import 'package:expense_tracker/views/dashboard/dashboard_screen.dart';
import 'package:expense_tracker/views/dashboard/analytics_screen.dart';
import 'package:expense_tracker/views/budgets/budgets_screen.dart';
import 'package:expense_tracker/views/goals/goals_screen.dart';
import 'package:expense_tracker/views/reports/reports_screen.dart';
import 'package:expense_tracker/views/settings/settings_screen.dart';
import 'package:expense_tracker/views/widgets/animated_background.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    BudgetsScreen(),
    GoalsScreen(),
    ReportsScreen(),
  ];

  final List<String> _titles = const [
    'Financial Dashboard',
    'Spending Analytics',
    'Monthly Budgets',
    'Savings Goals',
    'Reports & Export',
  ];

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<FinanceProvider>(
          builder: (context, finance, child) {
            final unread = finance.notifications.where((n) => !n.isRead).toList();
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Notifications (${unread.length})',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      if (finance.notifications.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            finance.clearAllNotifications();
                          },
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                  Divider(color: AppTheme.borderDark, height: 24),
                  Expanded(
                    child: finance.notifications.isEmpty
                        ? Center(
                            child: Text(
                              'No new alerts or reminders.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: finance.notifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final item = finance.notifications[idx];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: item.isRead ? AppTheme.cardDark.withOpacity(0.5) : AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: item.isRead ? AppTheme.borderDark : AppTheme.primary.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: item.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(item.dateTime),
                                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.message,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: item.isRead ? AppTheme.textSecondary.withOpacity(0.7) : AppTheme.textSecondary,
                                      ),
                                    ),
                                    if (!item.isRead) ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: InkWell(
                                          onTap: () {
                                            finance.markNotificationAsRead(item.id);
                                          },
                                          child: Text(
                                            'Mark read',
                                            style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final unreadCount = finance.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                onPressed: () => _showNotificationsPanel(context),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentExpense,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Settings Gear
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: AnimatedMeshBackground(child: _screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_rounded, color: AppTheme.primary),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            activeIcon: Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_rounded),
            activeIcon: Icon(Icons.wallet_rounded, color: AppTheme.primary),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            activeIcon: Icon(Icons.savings_rounded, color: AppTheme.primary),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description_rounded, color: AppTheme.primary),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}