import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/app_state.dart';
import 'package:expense_tracker/providers/finance_provider.dart';
import 'package:expense_tracker/views/transactions/transactions_screen.dart';
import 'package:expense_tracker/views/widgets/hover_element.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  IconData _getCategoryIcon(String category, bool isIncome) {
    if (isIncome) {
      switch (category) {
        case 'Salary':
          return Icons.payments_rounded;
        case 'Freelancing':
          return Icons.code_rounded;
        case 'Business':
          return Icons.storefront_rounded;
        case 'Investments':
          return Icons.trending_up_rounded;
        case 'Scholarships':
          return Icons.school_rounded;
        default:
          return Icons.account_balance_wallet_rounded;
      }
    } else {
      switch (category) {
        case 'Food':
          return Icons.restaurant_rounded;
        case 'Transportation':
          return Icons.directions_transit_rounded;
        case 'Education':
          return Icons.menu_book_rounded;
        case 'Entertainment':
          return Icons.local_play_rounded;
        case 'Healthcare':
          return Icons.favorite_rounded;
        case 'Shopping':
          return Icons.shopping_bag_rounded;
        case 'Utilities':
          return Icons.bolt_rounded;
        case 'Rent':
          return Icons.home_rounded;
        default:
          return Icons.receipt_long_rounded;
      }
    }
  }

  Color _getCategoryColor(String category, bool isIncome) {
    if (isIncome) return AppTheme.accentIncome;
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transportation':
        return Colors.blue;
      case 'Education':
        return Colors.cyan;
      case 'Entertainment':
        return Colors.pink;
      case 'Healthcare':
        return Colors.teal;
      case 'Shopping':
        return Colors.purple;
      case 'Utilities':
        return Colors.amber;
      case 'Rent':
        return Colors.brown;
      default:
        return AppTheme.accentExpense;
    }
  }

  void _showAddTransactionSheet(BuildContext context, bool isIncome) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AddTransactionSheet(isIncome: isIncome);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final appState = Provider.of<AppState>(context);

    final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    // Calculate budget utilization for current month
    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(now);
    final currentMonthBudgets = finance.budgets.where((b) => b.monthYear == currentMonthStr).toList();
    
    double totalBudgetLimit = currentMonthBudgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    double totalBudgetSpent = currentMonthBudgets.fold(0.0, (sum, b) {
      final spent = finance.getSpentForCategory(b.category, currentMonthStr);
      return sum + (spent > b.limitAmount ? b.limitAmount : spent); // cap spent at limit for overall meter
    });
    double overallUtilization = totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit) : 0.0;

    return RefreshIndicator(
      onRefresh: () => finance.loadAllData(),
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  Text(
                    appState.currentUserName ?? 'Finance User',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!appState.useFirebase)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSavings.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentSavings.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 14, color: AppTheme.accentSavings),
                      SizedBox(width: 6),
                      Text('Local Mode', style: TextStyle(color: AppTheme.accentSavings, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Core Net Balance Card
          HoverAnimatedElement(
            borderRadius: 24,
            glowColor: AppTheme.primary,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NET ACCOUNT BALANCE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    format.format(finance.currentBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.arrow_downward_rounded, color: AppTheme.accentIncome, size: 16),
                                SizedBox(width: 4),
                                Text('Income', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              format.format(finance.totalIncome),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 35, color: Colors.white24),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded, color: AppTheme.accentExpense, size: 16),
                                SizedBox(width: 4),
                                Text('Expenses', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              format.format(finance.totalExpenses),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Action buttons
          Row(
            children: [
              Expanded(
                child: HoverAnimatedElement(
                  scaleOnHover: 1.03,
                  glowColor: AppTheme.accentIncome,
                  borderRadius: 16,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTransactionSheet(context, true),
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                    label: const Text('Add Income'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentIncome,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HoverAnimatedElement(
                  scaleOnHover: 1.03,
                  glowColor: AppTheme.accentExpense,
                  borderRadius: 16,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTransactionSheet(context, false),
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentExpense,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Budget Utilization Overview Card
          if (totalBudgetLimit > 0) ...[
            HoverAnimatedElement(
              borderRadius: 20,
              glowColor: overallUtilization >= 1.0
                  ? AppTheme.accentExpense
                  : overallUtilization >= 0.8
                      ? AppTheme.accentWarning
                      : AppTheme.accentIncome,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Budget Utilization',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                        ),
                        Text(
                          '${(overallUtilization * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: overallUtilization >= 1.0
                                ? AppTheme.accentExpense
                                : overallUtilization >= 0.8
                                    ? AppTheme.accentWarning
                                    : AppTheme.accentIncome,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: overallUtilization > 1.0 ? 1.0 : overallUtilization,
                        minHeight: 10,
                        backgroundColor: AppTheme.borderDark,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overallUtilization >= 1.0
                              ? AppTheme.accentExpense
                              : overallUtilization >= 0.8
                                  ? AppTheme.accentWarning
                                  : AppTheme.accentIncome,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spent ${format.format(totalBudgetSpent)} out of ${format.format(totalBudgetLimit)} total budgets.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Recent Transactions Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transaction list
          finance.transactions.isEmpty
              ? HoverAnimatedElement(
                  borderRadius: 20,
                  glowColor: AppTheme.primary,
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions recorded yet.',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the add buttons above or go to Settings to seed demo sandbox records.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: finance.transactions.length > 5 ? 5 : finance.transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final tx = finance.transactions[idx];
                    final color = _getCategoryColor(tx.category, tx.isIncome);
                    final icon = _getCategoryIcon(tx.category, tx.isIncome);

                    return HoverAnimatedElement(
                      borderRadius: 16,
                      glowColor: color,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderDark, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        tx.category,
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.textSecondary)),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd MMM').format(tx.dateTime),
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${tx.isIncome ? '+' : '-'}${format.format(tx.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: tx.isIncome ? AppTheme.accentIncome : AppTheme.accentExpense,
                                fontSize: 15,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// Dialog sheet to add transaction
class AddTransactionSheet extends StatefulWidget {
  final bool isIncome;
  const AddTransactionSheet({super.key, required this.isIncome});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isAutoCategorized = false;

  final List<String> _incomeCategories = ['Salary', 'Freelancing', 'Business', 'Investments', 'Scholarships', 'Other Income'];
  final List<String> _expenseCategories = ['Food', 'Transportation', 'Education', 'Entertainment', 'Healthcare', 'Shopping', 'Utilities', 'Rent'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.isIncome ? _incomeCategories.first : _expenseCategories.first;
    _selectedDate = DateTime.now();

    // Listen to changes in title for smart categorization
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    final title = _titleController.text;
    if (title.isEmpty) return;

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final predicted = finance.predictCategory(title, widget.isIncome);
    
    if (predicted != _selectedCategory) {
      setState(() {
        _selectedCategory = predicted;
        _isAutoCategorized = true;
      });
    }
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.cardDark,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: AppTheme.bgDark,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text);
    final notes = _notesController.text.trim();

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    await finance.addTransaction(
      title: title,
      amount: amount,
      category: _selectedCategory,
      dateTime: _selectedDate,
      isIncome: widget.isIncome,
      notes: notes,
    );

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
                    widget.isIncome ? 'Add Income Receipt' : 'Add Expense Receipt',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: AppTheme.borderDark, height: 24),
              
              // Title Field
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Transaction Title',
                  hintText: 'e.g. McDonalds Burger, Salary',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  suffixText: widget.isIncome ? 'IN' : 'OUT',
                  suffixStyle: TextStyle(
                    color: widget.isIncome ? AppTheme.accentIncome : AppTheme.accentExpense,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter an amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Please enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: TextStyle(color: AppTheme.textPrimary),
                dropdownColor: AppTheme.cardDark,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  suffixIcon: _isAutoCategorized
                      ? Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentSavings.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentSavings.withOpacity(0.4)),
                          ),
                          child: Text(
                            'Smart Predict',
                            style: TextStyle(color: AppTheme.accentSavings, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
                items: (widget.isIncome ? _incomeCategories : _expenseCategories)
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                      _isAutoCategorized = false; // manual override
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date Picker Button
              InkWell(
                onTap: _presentDatePicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Transaction Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        ),
                      ),
                      Text(
                        'Change',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppTheme.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional details...',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isIncome ? AppTheme.accentIncome : AppTheme.accentExpense,
                ),
                child: Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}