import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/finance_provider.dart';
import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/views/widgets/hover_element.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  final List<String> _categories = const [
    'Food',
    'Transportation',
    'Education',
    'Entertainment',
    'Healthcare',
    'Shopping',
    'Utilities',
    'Rent'
  ];

  void _showSetBudgetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return const SetBudgetSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(now);
    final monthName = DateFormat('MMMM yyyy').format(now);

    final activeBudgets = finance.budgets.where((b) => b.monthYear == currentMonthStr).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar header info card
            HoverAnimatedElement(
              borderRadius: 20,
              glowColor: AppTheme.primary,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Budget Cycle',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showSetBudgetSheet(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Configure'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Category-wise Budget Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            activeBudgets.isEmpty
                ? GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.wallet_rounded, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No budgets set for this month.',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Configure" above to set category spending limits.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeBudgets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final budget = activeBudgets[idx];
                      final spent = finance.getSpentForCategory(budget.category, currentMonthStr);
                      final limit = budget.limitAmount;
                      final ratio = limit > 0 ? (spent / limit) : 0.0;
                      final percent = ratio * 100;

                      Color progressColor = AppTheme.accentIncome;
                      String statusText = 'Under control';
                      IconData statusIcon = Icons.check_circle_outline_rounded;

                      if (spent >= limit) {
                        progressColor = AppTheme.accentExpense;
                        statusText = 'Limit Exceeded!';
                        statusIcon = Icons.error_outline_rounded;
                      } else if (ratio >= 0.8) {
                        progressColor = AppTheme.accentWarning;
                        statusText = 'Close to limit';
                        statusIcon = Icons.warning_amber_rounded;
                      }

                      return HoverAnimatedElement(
                        borderRadius: 20,
                        glowColor: progressColor,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: spent >= limit
                                  ? AppTheme.accentExpense.withOpacity(0.4)
                                  : ratio >= 0.8
                                      ? AppTheme.accentWarning.withOpacity(0.4)
                                      : AppTheme.borderDark,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        budget.category == 'Food'
                                            ? Icons.restaurant_rounded
                                            : budget.category == 'Rent'
                                                ? Icons.home_rounded
                                                : Icons.category_rounded,
                                        color: progressColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        budget.category,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  // Delete budget action
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: progressColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(statusIcon, color: progressColor, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                color: progressColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textSecondary),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          finance.deleteBudget(budget.id, budget.userId);
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: ratio > 1.0 ? 1.0 : ratio),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  builder: (ctx, val, child) {
                                    return LinearProgressIndicator(
                                      value: val,
                                      minHeight: 8,
                                      backgroundColor: AppTheme.borderDark,
                                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                    );
                                  },
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Spent: ${format.format(spent)}',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Limit: ${format.format(limit)}',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (spent > limit) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '⚠️ Over budget by ${format.format(spent - limit)}',
                                  style: TextStyle(color: AppTheme.accentExpense, fontSize: 11, fontWeight: FontWeight.bold),
                                )
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// Config sheet to set category budget
class SetBudgetSheet extends StatefulWidget {
  const SetBudgetSheet({super.key});

  @override
  State<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<SetBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  late String _selectedCategory;

  final List<String> _categories = const [
    'Food',
    'Transportation',
    'Education',
    'Entertainment',
    'Healthcare',
    'Shopping',
    'Utilities',
    'Rent'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final limit = double.parse(_limitController.text);
    final now = DateTime.now();
    final monthYearStr = DateFormat('yyyy-MM').format(now);

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    await finance.saveBudget(_selectedCategory, limit, monthYearStr);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final paddingBottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: paddingBottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Configure Monthly Budget',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: AppTheme.borderDark, height: 24),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: TextStyle(color: AppTheme.textPrimary),
                dropdownColor: AppTheme.cardDark,
                decoration: const InputDecoration(labelText: 'Expense Category', prefixIcon: Icon(Icons.category_outlined)),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Spending Limit (₹)',
                  hintText: 'e.g. 5000',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter a limit';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Please enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Budget Limit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}