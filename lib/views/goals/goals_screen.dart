import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/finance_provider.dart';
import 'package:expense_tracker/models/savings_goal.dart';
import 'package:expense_tracker/views/widgets/hover_element.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return const AddGoalSheet();
      },
    );
  }

  void _showContributeSheet(BuildContext context, SavingsGoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ContributeGoalSheet(goal: goal);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goals Header Info Card
            HoverAnimatedElement(
              borderRadius: 20,
              glowColor: AppTheme.accentSavings,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.savings_rounded, color: AppTheme.accentSavings, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Target Savings',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          Text(
                            format.format(finance.goals.fold(0.0, (sum, g) => sum + g.targetAmount)),
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
                      onPressed: () => _showAddGoalSheet(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Goal'),
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
              'Savings Milestones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            finance.goals.isEmpty
                ? GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.flag_outlined, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No active savings goals.',
                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Add Goal" above to configure your targets (e.g. laptop, car, fund).',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: finance.goals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final goal = finance.goals[idx];
                      final pct = goal.progressPercentage;
                      final isDone = goal.isCompleted;

                      return HoverAnimatedElement(
                        borderRadius: 20,
                        glowColor: isDone ? AppTheme.accentIncome : AppTheme.accentSavings,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDone ? AppTheme.accentIncome.withOpacity(0.4) : AppTheme.borderDark,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      goal.title,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textSecondary),
                                    onPressed: () {
                                      finance.deleteGoal(goal.id);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target Date: ${DateFormat('dd MMM yyyy').format(goal.targetDate)}',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Saved: ${format.format(goal.currentAmount)}',
                                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Target: ${format.format(goal.targetAmount)}',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: pct / 100),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  builder: (ctx, val, child) {
                                    return LinearProgressIndicator(
                                      value: val,
                                      minHeight: 12,
                                      backgroundColor: AppTheme.borderDark,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDone ? AppTheme.accentIncome : AppTheme.accentSavings,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress: ${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: isDone ? AppTheme.accentIncome : AppTheme.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isDone)
                                    Text(
                                      'Achieved! 🎉',
                                      style: TextStyle(color: AppTheme.accentIncome, fontWeight: FontWeight.bold, fontSize: 11),
                                    )
                                ],
                              ),
                              if (!isDone) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showContributeSheet(context, goal),
                                  icon: const Icon(Icons.savings_outlined, size: 16),
                                  label: const Text('Add Savings Contribution'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentSavings,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
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

// Dialog sheet to add savings goal
class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _initialController = TextEditingController();
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    _targetDate = DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _initialController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)), // 5 years max
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
        _targetDate = pickedDate;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final target = double.parse(_targetController.text);
    final initial = _initialController.text.isEmpty ? 0.0 : double.parse(_initialController.text);

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    await finance.saveGoal(
      title: title,
      targetAmount: target,
      currentAmount: initial,
      targetDate: _targetDate,
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
                    'Setup Savings Goal',
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
                decoration: const InputDecoration(labelText: 'Goal Title', hintText: 'e.g. New Laptop, Vacation Fund'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a goal title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Target Amount (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter target amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Please enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _initialController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Initial Saved Balance (Optional)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                validator: (val) {
                  if (val != null && val.isNotEmpty) {
                    final parsed = double.tryParse(val);
                    if (parsed == null || parsed < 0) return 'Please enter a valid positive number';
                    // Must not exceed target
                    if (_targetController.text.isNotEmpty) {
                      final targetVal = double.tryParse(_targetController.text);
                      if (targetVal != null && parsed > targetVal) return 'Initial saved cannot exceed target';
                    }
                  }
                  return null;
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
                          'Target Date: ${DateFormat('dd MMMM yyyy').format(_targetDate)}',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        ),
                      ),
                      Text('Change', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _submit,
                child: const Text('Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog sheet to make a contribution
class ContributeGoalSheet extends StatefulWidget {
  final SavingsGoalModel goal;
  const ContributeGoalSheet({super.key, required this.goal});

  @override
  State<ContributeGoalSheet> createState() => _ContributeGoalSheetState();
}

class _ContributeGoalSheetState extends State<ContributeGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amt = double.parse(_amountController.text);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    
    await finance.contributeToGoal(widget.goal.id, amt);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contributed ₹${NumberFormat('#,##,###').format(amt)} to "${widget.goal.title}".'),
          backgroundColor: AppTheme.accentIncome,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingBottom = MediaQuery.of(context).viewInsets.bottom;
    final remaining = widget.goal.targetAmount - widget.goal.currentAmount;
    final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

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
                    'Contribute to Goal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: AppTheme.borderDark, height: 24),
              Text(
                'Contributing to: "${widget.goal.title}"',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Text(
                'Remaining to save: ${format.format(remaining)}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Contribution Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter contribution amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Please enter a valid positive number';
                  if (parsed > remaining) return 'Cannot contribute more than remaining target';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentSavings,
                ),
                child: const Text('Confirm Deposit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}