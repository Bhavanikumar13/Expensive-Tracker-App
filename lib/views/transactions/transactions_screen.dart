import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/finance_provider.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/views/widgets/animated_background.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'All'; // 'All', 'Income', 'Expense'
  String _categoryFilter = 'All';

  final List<String> _allCategories = [
    'All',
    'Salary',
    'Freelancing',
    'Business',
    'Investments',
    'Scholarships',
    'Food',
    'Transportation',
    'Education',
    'Entertainment',
    'Healthcare',
    'Shopping',
    'Utilities',
    'Rent',
    'Other Income'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  void _showEditTransactionSheet(BuildContext context, TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return EditTransactionSheet(transaction: transaction);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    // Apply Search & Filters
    final filteredTransactions = finance.transactions.where((tx) {
      // 1. Search Query filter
      final matchesSearch = tx.title.toLowerCase().contains(_searchQuery) ||
          tx.notes.toLowerCase().contains(_searchQuery) ||
          tx.category.toLowerCase().contains(_searchQuery);

      // 2. Type filter
      final matchesType = _typeFilter == 'All' ||
          (_typeFilter == 'Income' && tx.isIncome) ||
          (_typeFilter == 'Expense' && !tx.isIncome);

      // 3. Category filter
      final matchesCategory = _categoryFilter == 'All' || tx.category == _categoryFilter;

      return matchesSearch && matchesType && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Logs'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: AnimatedMeshBackground(
        child: Column(
          children: [
          // Filter Bar Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search title, category, notes...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Dropdowns & Types
                Row(
                  children: [
                    // Type selector
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _typeFilter,
                            dropdownColor: AppTheme.cardDark,
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            items: ['All', 'Income', 'Expense']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _typeFilter = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category selector
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categoryFilter,
                            dropdownColor: AppTheme.cardDark,
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            isExpanded: true,
                            items: _allCategories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _categoryFilter = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Count row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredTransactions.length} records',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (_typeFilter != 'All' || _categoryFilter != 'All' || _searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _typeFilter = 'All';
                        _categoryFilter = 'All';
                      });
                    },
                    child: Text('Reset Filters', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List body
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 54, color: AppTheme.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions match query.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final tx = filteredTransactions[idx];
                      final color = _getCategoryColor(tx.category, tx.isIncome);
                      final icon = _getCategoryIcon(tx.category, tx.isIncome);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tx.category} • ${DateFormat('dd MMM yyyy').format(tx.dateTime)}',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                  ),
                                  if (tx.notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tx.notes,
                                      style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 11, fontStyle: FontStyle.italic),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${tx.isIncome ? '+' : '-'}${format.format(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: tx.isIncome ? AppTheme.accentIncome : AppTheme.accentExpense,
                                    fontSize: 14,
                                  ),
                                ),

                                // Options Menu Trigger
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textSecondary),
                                  padding: EdgeInsets.zero,
                                  color: AppTheme.cardDark,
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
                                          SizedBox(width: 8),
                                          Text('Edit', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_forever_rounded, size: 16, color: AppTheme.accentExpense),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(fontSize: 13, color: AppTheme.accentExpense)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (String action) {
                                    if (action == 'edit') {
                                      _showEditTransactionSheet(context, tx);
                                    } else if (action == 'delete') {
                                      finance.deleteTransaction(tx.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    );
  }
}

// Edit transaction drawer sheet
class EditTransactionSheet extends StatefulWidget {
  final TransactionModel transaction;
  const EditTransactionSheet({super.key, required this.transaction});

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late String _selectedCategory;
  late DateTime _selectedDate;

  final List<String> _incomeCategories = ['Salary', 'Freelancing', 'Business', 'Investments', 'Scholarships', 'Other Income'];
  final List<String> _expenseCategories = ['Food', 'Transportation', 'Education', 'Entertainment', 'Healthcare', 'Shopping', 'Utilities', 'Rent'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _notesController = TextEditingController(text: widget.transaction.notes);
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.dateTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  void _submitData() {
    if (!_formKey.currentState!.validate()) return;

    final updatedTx = widget.transaction.copyWith(
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      dateTime: _selectedDate,
      notes: _notesController.text.trim(),
    );

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    finance.updateTransaction(updatedTx);

    Navigator.pop(context);
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
                    'Modify Transaction',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: AppTheme.borderDark, height: 24),

              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Transaction Title'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter an amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Please enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: TextStyle(color: AppTheme.textPrimary),
                dropdownColor: AppTheme.cardDark,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                items: (widget.transaction.isIncome ? _incomeCategories : _expenseCategories)
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 16),

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
                          'Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        ),
                      ),
                      Text('Change', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Notes (Optional)', prefixIcon: Icon(Icons.notes_rounded)),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}