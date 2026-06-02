import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/finance_provider.dart';
import 'package:expense_tracker/views/widgets/hover_element.dart';
import 'package:expense_tracker/core/file_exporter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  
  // Ledger Search & Filter state
  final _searchController = TextEditingController();
  String _selectedCategoryFilter = 'All';

  final List<int> _years = [2024, 2025, 2026, 2027];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _downloadReportFile(String filename, String content) async {
    try {
      final result = await FileExporter.exportFile(filename, content);
      if (!mounted) return;
      if (result == 'web') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded "$filename" to your browser!'),
            backgroundColor: AppTheme.accentIncome,
          ),
        );
      } else if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved locally to: $result'),
            backgroundColor: AppTheme.accentIncome,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString().replaceAll('Exception: ', '')}. Copied content to clipboard.'),
          backgroundColor: AppTheme.accentExpense,
        ),
      );
    }
  }

  void _showExportPreview(String filename, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              filename,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Report Export Preview & Direct Download',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: AppTheme.borderDark, height: 24),
                  
                  // Action buttons: Download & Copy
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _downloadReportFile(filename, content);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Download File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentIncome,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied to clipboard!'), backgroundColor: AppTheme.primary),
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Text'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // File Content viewer
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Text(
                          content,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                      ),
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

  // Calculate Monthly Financial Health Score (0 - 100)
  int _calculateHealthScore(double income, double expense, int totalBudgets, int exceededBudgets) {
    if (income == 0 && expense == 0) return 0;
    
    double score = 0;

    // 1. Savings Rate Contribution (Max 40 points)
    final double net = income - expense;
    final double savingsRate = income > 0 ? (net / income) * 100 : 0.0;
    if (savingsRate >= 30) {
      score += 40;
    } else if (savingsRate >= 15) {
      score += 30;
    } else if (savingsRate > 0) {
      score += 15;
    }

    // 2. Budget Compliance Contribution (Max 40 points)
    if (totalBudgets == 0) {
      score += 30; // default points for healthy low spending/no flags
    } else {
      double complianceRatio = (totalBudgets - exceededBudgets) / totalBudgets;
      score += complianceRatio * 40;
    }

    // 3. Overall Savings Retention (Max 20 points)
    if (net > 0) {
      score += 20;
    } else if (net == 0) {
      score += 10;
    }

    return score.round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    final monthStr = DateFormat('yyyy-MM').format(DateTime(_selectedYear, _selectedMonth));
    final monthName = _months[_selectedMonth - 1];

    final monthlyTxs = finance.transactions.where((t) => DateFormat('yyyy-MM').format(t.dateTime) == monthStr).toList();
    final monthlyBudgets = finance.budgets.where((b) => b.monthYear == monthStr).toList();

    final income = monthlyTxs.where((t) => t.isIncome).fold(0.0, (sum, item) => sum + item.amount);
    final expense = monthlyTxs.where((t) => !t.isIncome).fold(0.0, (sum, item) => sum + item.amount);
    final net = income - expense;

    // Budget auditor calculation
    int exceededBudgets = 0;
    for (var b in monthlyBudgets) {
      final spent = finance.getSpentForCategory(b.category, monthStr);
      if (spent > b.limitAmount) {
        exceededBudgets++;
      }
    }

    final healthScore = _calculateHealthScore(income, expense, monthlyBudgets.length, exceededBudgets);

    // Highest category calculation
    final Map<String, double> categorySums = {};
    for (var tx in monthlyTxs.where((t) => !t.isIncome)) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0.0) + tx.amount;
    }
    final sortedCategories = categorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final highestCategoryName = sortedCategories.isNotEmpty ? sortedCategories.first.key : 'None';
    final highestCategoryAmt = sortedCategories.isNotEmpty ? sortedCategories.first.value : 0.0;

    // Filtered ledger transactions list
    final filteredLedgerTxs = monthlyTxs.where((tx) {
      final matchesSearch = tx.title.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'All' || tx.category == _selectedCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    // Unique categories present in this month's transactions
    final availableCategories = {'All', ...monthlyTxs.map((t) => t.category)};

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Month/Year Selector Card
          HoverAnimatedElement(
            borderRadius: 20,
            glowColor: AppTheme.primary,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text('Report Cycle: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        dropdownColor: AppTheme.cardDark,
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(_months[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMonth = val);
                        },
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      dropdownColor: AppTheme.cardDark,
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      items: _years.map((y) {
                        return DropdownMenuItem(value: y, child: Text(y.toString()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Total Overview Cards
          if (monthlyTxs.isEmpty) ...[
            HoverAnimatedElement(
              borderRadius: 20,
              glowColor: AppTheme.primary,
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    Icon(Icons.folder_off_outlined, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No transaction logs for $monthName $_selectedYear.',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try changing the month/year filter, add records, or seed Sandbox Data in Settings.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Financial Health Score Gauge
            HoverAnimatedElement(
              borderRadius: 20,
              glowColor: healthScore >= 80
                  ? AppTheme.accentIncome
                  : healthScore >= 50
                      ? AppTheme.accentWarning
                      : AppTheme.accentExpense,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Radial Score Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: healthScore / 100,
                            strokeWidth: 8,
                            backgroundColor: AppTheme.borderDark,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              healthScore >= 80
                                  ? AppTheme.accentIncome
                                  : healthScore >= 50
                                      ? AppTheme.accentWarning
                                      : AppTheme.accentExpense,
                            ),
                          ),
                        ),
                        Text(
                          '$healthScore',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FINANCIAL HEALTH SCORE',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            healthScore >= 80
                                ? 'Stable surplus & high budget discipline!'
                                : healthScore >= 50
                                    ? 'Moderately healthy. Review over-budget alerts.'
                                    : 'High spending deficit. Immediate action advised.',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Report Summary Card
            HoverAnimatedElement(
              borderRadius: 20,
              glowColor: net >= 0 ? AppTheme.accentSavings : AppTheme.accentExpense,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$monthName $_selectedYear Performance Summary',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Total Inflow (Income)', format.format(income), AppTheme.accentIncome),
                    Divider(color: AppTheme.borderDark, height: 24),
                    _buildStatRow('Total Outflow (Expenses)', format.format(expense), AppTheme.accentExpense),
                    Divider(color: AppTheme.borderDark, height: 24),
                    _buildStatRow('Net Surplus/Savings', format.format(net), net >= 0 ? AppTheme.accentSavings : AppTheme.accentExpense),
                    Divider(color: AppTheme.borderDark, height: 24),
                    _buildStatRow(
                      'Peak Spending Sector',
                      highestCategoryName == 'None'
                          ? 'None'
                          : '$highestCategoryName (${format.format(highestCategoryAmt)})',
                      AppTheme.accentWarning,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Budget Compliance Auditor Section
            if (monthlyBudgets.isNotEmpty) ...[
              Text(
                'Budget Compliance Auditor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: monthlyBudgets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final budget = monthlyBudgets[idx];
                  final spent = finance.getSpentForCategory(budget.category, monthStr);
                  final ratio = budget.limitAmount > 0 ? (spent / budget.limitAmount) : 0.0;
                  final isExceeded = spent > budget.limitAmount;

                  return HoverAnimatedElement(
                    borderRadius: 14,
                    glowColor: isExceeded ? AppTheme.accentExpense : AppTheme.accentIncome,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isExceeded
                                    ? Icons.cancel_rounded
                                    : ratio >= 0.8
                                        ? Icons.warning_rounded
                                        : Icons.check_circle_rounded,
                                color: isExceeded
                                    ? AppTheme.accentExpense
                                    : ratio >= 0.8
                                        ? AppTheme.accentWarning
                                        : AppTheme.accentIncome,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                budget.category,
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${format.format(spent)} / ${format.format(budget.limitAmount)}',
                                style: TextStyle(
                                  color: isExceeded ? AppTheme.accentExpense : AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isExceeded
                                    ? 'Violated'
                                    : ratio >= 0.8
                                        ? 'Warning'
                                        : 'OK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isExceeded
                                      ? AppTheme.accentExpense
                                      : ratio >= 0.8
                                          ? AppTheme.accentWarning
                                          : AppTheme.accentIncome,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Export Options
            Text(
              'Financial Statement Exporter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final content = finance.generateCsvReport(_selectedYear, _selectedMonth);
                      _showExportPreview('statement_$monthStr.csv', content);
                    },
                    child: HoverAnimatedElement(
                      borderRadius: 20,
                      glowColor: AppTheme.accentIncome,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Column(
                          children: [
                             Icon(Icons.table_chart_rounded, color: AppTheme.accentIncome, size: 32),
                             SizedBox(height: 10),
                             Text('Export CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                             SizedBox(height: 4),
                             Text('Spreadsheet format', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final content = finance.generateTextReport(_selectedYear, _selectedMonth);
                      _showExportPreview('statement_$monthStr.txt', content);
                    },
                    child: HoverAnimatedElement(
                      borderRadius: 20,
                      glowColor: AppTheme.accentSavings,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.text_snippet_rounded, color: AppTheme.accentSavings, size: 32),
                            SizedBox(height: 10),
                            Text('Export Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Audit statement', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Monthly Interactive Ledger Panel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Statement Ledger',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  '${filteredLedgerTxs.length} items',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                )
              ],
            ),
            const SizedBox(height: 12),
            
            // Search Bar inside ledger
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search title...',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 10),

            // Category Filter Chips Row
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: availableCategories.map((cat) {
                  final active = _selectedCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: active,
                      label: Text(cat),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : AppTheme.textSecondary,
                      ),
                      backgroundColor: AppTheme.cardDark,
                      selectedColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: active ? AppTheme.primary : AppTheme.borderDark),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryFilter = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Ledger Transaction list
            filteredLedgerTxs.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Center(
                      child: Text(
                        'No matching statement logs found.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredLedgerTxs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final tx = filteredLedgerTxs[idx];
                      final isInc = tx.isIncome;
                      final txColor = isInc ? AppTheme.accentIncome : AppTheme.accentExpense;

                      return HoverAnimatedElement(
                        borderRadius: 14,
                        glowColor: txColor,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: txColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isInc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: txColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${tx.category} | ${DateFormat('dd MMM').format(tx.dateTime)}',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isInc ? '+' : '-'}${format.format(tx.amount)}',
                                style: TextStyle(fontWeight: FontWeight.w900, color: txColor, fontSize: 14),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ],
    );
  }
}