import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme.dart';
import 'package:expense_tracker/providers/finance_provider.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/views/widgets/hover_element.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _activeChartIndex = 0; // 0: Pie (Categories), 1: Bar (Monthly), 2: Line (Trends)
  String _selectedRange = 'This Month'; // 'This Month', 'Last 30 Days', 'Last 90 Days', 'All Time'

  Color _getCategoryColor(String category) {
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
        return AppTheme.primary;
    }
  }

  Widget _buildRangeButton(String range) {
    final active = _selectedRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRange = range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            range,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? AppTheme.primary : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final format = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    // Apply Date Range Filter to the Transaction logs
    final now = DateTime.now();
    final filteredTxs = finance.transactions.where((t) {
      if (_selectedRange == 'This Month') {
        return t.dateTime.year == now.year && t.dateTime.month == now.month;
      } else if (_selectedRange == 'Last 30 Days') {
        return t.dateTime.isAfter(now.subtract(const Duration(days: 30)));
      } else if (_selectedRange == 'Last 90 Days') {
        return t.dateTime.isAfter(now.subtract(const Duration(days: 90)));
      } else {
        return true; // All Time
      }
    }).toList();

    final expenseTransactions = filteredTxs.where((t) => !t.isIncome).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: finance.transactions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'No Analytics Available',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record some transactions or seed sandbox data in Settings to view charts.',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Range Filter Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: ['This Month', 'Last 30 Days', 'Last 90 Days', 'All Time']
                          .map((range) => _buildRangeButton(range))
                          .toList(),
                    ),
                  ),

                  // Segment Selector Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Categories', Icons.pie_chart_outline_rounded),
                        _buildTabButton(1, 'In vs Out', Icons.bar_chart_rounded),
                        _buildTabButton(2, 'Trends', Icons.show_chart_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Active Chart Viewer
                  HoverAnimatedElement(
                    borderRadius: 20,
                    glowColor: AppTheme.primary,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        height: 320,
                        child: _buildActiveChart(expenseTransactions, filteredTxs),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Smart Insights Panel
                  _buildSmartInsights(filteredTxs, expenseTransactions, format),
                  const SizedBox(height: 24),

                  // Data Breakdown Section
                  if (_activeChartIndex == 0) ...[
                    Text(
                      'Category Breakdown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryLegendList(expenseTransactions, format),
                  ] else if (_activeChartIndex == 1) ...[
                    Text(
                      'Cash Flow Statistics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildCashFlowSummary(filteredTxs, format),
                  ] else ...[
                    Text(
                      'Recent Expense Logs in Filter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentExpenseTrends(expenseTransactions, format),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final active = _activeChartIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeChartIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChart(List<TransactionModel> expenseTxs, List<TransactionModel> filteredTxs) {
    switch (_activeChartIndex) {
      case 0:
        return _buildPieChart(expenseTxs);
      case 1:
        return _buildBarChart(filteredTxs);
      case 2:
        return _buildLineChart(expenseTxs);
      default:
        return Container();
    }
  }

  // --- 1. PIE CHART: Categories ---
  Widget _buildPieChart(List<TransactionModel> expenseTxs) {
    if (expenseTxs.isEmpty) {
      return const Center(child: Text('No expenses recorded for this filter range.'));
    }

    final Map<String, double> categorySums = {};
    double totalExpenseSum = 0;
    for (var tx in expenseTxs) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0.0) + tx.amount;
      totalExpenseSum += tx.amount;
    }

    final sections = categorySums.entries.map((entry) {
      final color = _getCategoryColor(entry.key);
      final ratio = entry.value / totalExpenseSum;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${(ratio * 100).toStringAsFixed(0)}%',
        radius: 65,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 55,
              sections: sections,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Mini Legend
        SizedBox(
          width: 110,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categorySums.keys.map((cat) {
                final col = _getCategoryColor(cat);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat,
                          style: TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }

  // --- 2. BAR CHART: Income vs Expense ---
  Widget _buildBarChart(List<TransactionModel> filteredTxs) {
    final double income = filteredTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final double expense = filteredTxs.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

    if (income == 0 && expense == 0) {
      return const Center(child: Text('No cash flow records.'));
    }

    final double maxVal = income > expense ? income : expense;
    final double gridInterval = maxVal > 0 ? maxVal / 5 : 1000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: maxVal * 1.15,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: gridInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return Text('0', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary));
                final formatted = NumberFormat.compact().format(value);
                return Text(formatted, style: TextStyle(fontSize: 9, color: AppTheme.textSecondary));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Income', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentIncome)),
                    );
                  case 1:
                    return Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Expenses', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentExpense)),
                    );
                  default:
                    return Container();
                }
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: gridInterval,
          getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.borderDark, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: income,
                color: AppTheme.accentIncome,
                width: 25,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: expense,
                color: AppTheme.accentExpense,
                width: 25,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. LINE CHART: Spending Trend ---
  Widget _buildLineChart(List<TransactionModel> expenseTxs) {
    if (expenseTxs.isEmpty) {
      return const Center(child: Text('No expense transactions to compute trend.'));
    }

    // Sort by date ascending
    final sorted = List<TransactionModel>.from(expenseTxs)..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    final List<FlSpot> spots = [];
    final trendPoints = sorted.length > 8 ? sorted.sublist(sorted.length - 8) : sorted;

    for (int i = 0; i < trendPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendPoints[i].amount));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2000,
          getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.borderDark, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < trendPoints.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(trendPoints[idx].dateTime),
                      style: TextStyle(fontSize: 8, color: AppTheme.textSecondary),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                final formatted = NumberFormat.compact().format(value);
                return Text(formatted, style: TextStyle(fontSize: 9, color: AppTheme.textSecondary));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  // --- Breakdown Widgets ---
  Widget _buildCategoryLegendList(List<TransactionModel> expenseTxs, NumberFormat format) {
    if (expenseTxs.isEmpty) return const SizedBox();

    final Map<String, double> categorySums = {};
    double total = 0;
    for (var tx in expenseTxs) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0.0) + tx.amount;
      total += tx.amount;
    }

    final sorted = categorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final entry = sorted[idx];
        final color = _getCategoryColor(entry.key);
        final ratio = entry.value / total;

        return HoverAnimatedElement(
          borderRadius: 16,
          glowColor: color,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      format.format(entry.value),
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${(ratio * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashFlowSummary(List<TransactionModel> filteredTxs, NumberFormat format) {
    final double income = filteredTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final double expense = filteredTxs.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final double net = income - expense;

    return Column(
      children: [
        _buildSummaryRow('Total Income Received', format.format(income), AppTheme.accentIncome, Icons.arrow_circle_down_rounded),
        const SizedBox(height: 8),
        _buildSummaryRow('Total Expenses Logged', format.format(expense), AppTheme.accentExpense, Icons.arrow_circle_up_rounded),
        const SizedBox(height: 8),
        _buildSummaryRow(
          'Net Savings Retention',
          format.format(net),
          net >= 0 ? AppTheme.accentSavings : AppTheme.accentExpense,
          net >= 0 ? Icons.savings_rounded : Icons.warning_amber_rounded,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valColor, IconData icon) {
    return HoverAnimatedElement(
      borderRadius: 16,
      glowColor: valColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Row(
          children: [
            Icon(icon, color: valColor, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold))),
            Text(value, style: TextStyle(color: valColor, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenseTrends(List<TransactionModel> expenseTxs, NumberFormat format) {
    if (expenseTxs.isEmpty) return const SizedBox();

    final sorted = List<TransactionModel>.from(expenseTxs)..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final limitList = sorted.length > 5 ? sorted.sublist(0, 5) : sorted;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: limitList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final tx = limitList[idx];
        final color = _getCategoryColor(tx.category);

        return HoverAnimatedElement(
          borderRadius: 12,
          glowColor: color,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        Text(
                          '${tx.category} | ${DateFormat('dd MMM').format(tx.dateTime)}',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '-${format.format(tx.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentExpense, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Dynamic Smart Insights Builder ---
  Widget _buildSmartInsights(
    List<TransactionModel> filteredTxs,
    List<TransactionModel> expenseTxs,
    NumberFormat format,
  ) {
    if (filteredTxs.isEmpty) return const SizedBox();

    final double income = filteredTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final double expense = filteredTxs.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final double net = income - expense;

    // 1. Savings Rate
    double savingsRate = income > 0 ? (net / income) * 100 : 0.0;
    String savingsEval = '';
    Color savingsColor = Colors.white;
    if (savingsRate >= 30) {
      savingsEval = 'Excellent';
      savingsColor = AppTheme.accentIncome;
    } else if (savingsRate >= 15) {
      savingsEval = 'Healthy';
      savingsColor = AppTheme.primary;
    } else if (savingsRate > 0) {
      savingsEval = 'Fair';
      savingsColor = AppTheme.accentWarning;
    } else {
      savingsEval = 'Deficit';
      savingsColor = AppTheme.accentExpense;
    }

    // 2. Highest Category
    final Map<String, double> categorySums = {};
    for (var tx in expenseTxs) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0.0) + tx.amount;
    }
    final sortedCategories = categorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final highestCat = sortedCategories.isNotEmpty ? sortedCategories.first.key : 'None';
    final highestCatAmt = sortedCategories.isNotEmpty ? sortedCategories.first.value : 0.0;

    // 3. Peak Day
    final Map<int, double> daySums = {};
    for (var tx in expenseTxs) {
      final weekday = tx.dateTime.weekday;
      daySums[weekday] = (daySums[weekday] ?? 0.0) + tx.amount;
    }
    final sortedDays = daySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final weekdays = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final peakDayName = sortedDays.isNotEmpty ? weekdays[sortedDays.first.key] : 'None';

    // 4. Financial Advice
    String advice = '';
    IconData adviceIcon = Icons.lightbulb_outline_rounded;
    Color adviceColor = AppTheme.primary;

    if (net < 0) {
      advice = 'Your spending exceeds your income. We recommend pausing non-essential purchases immediately.';
      adviceIcon = Icons.warning_amber_rounded;
      adviceColor = AppTheme.accentExpense;
    } else if (highestCat == 'Food' && highestCatAmt > 2000) {
      advice = 'Dining out is your primary expense. Setting a Food category budget can help save up to 15% more.';
      adviceColor = Colors.orange;
    } else if (highestCat == 'Shopping' && highestCatAmt > 1500) {
      advice = 'Shopping represents a significant portion of spending. Consider the 48-hour rule before buying.';
      adviceColor = Colors.purple;
    } else if (savingsRate >= 30) {
      advice = 'Incredible job! You saved ${savingsRate.toStringAsFixed(0)}% of your income. Consider contributing to active goals.';
      adviceIcon = Icons.verified_rounded;
      adviceColor = AppTheme.accentIncome;
    } else {
      advice = 'Try setting custom category budgets on the Budgets page to gain more granular control.';
    }

    return HoverAnimatedElement(
      borderRadius: 20,
      glowColor: adviceColor,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: AppTheme.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'Wealth Insights & Analytics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                ),
              ],
            ),
            Divider(color: AppTheme.borderDark, height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInsightStat(
                    'Savings Rate',
                    income > 0 ? '${savingsRate.toStringAsFixed(0)}%' : '0%',
                    savingsEval,
                    savingsColor,
                  ),
                ),
                Container(width: 1, height: 45, color: AppTheme.borderDark),
                Expanded(
                  child: _buildInsightStat(
                    'Peak Expense Day',
                    peakDayName,
                    'Most spending',
                    AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (highestCat != 'None') ...[
              _buildInsightRow(
                Icons.pie_chart_outline_rounded,
                'Top spending sector is ',
                highestCat,
                ' (${format.format(highestCatAmt)})',
                AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: adviceColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: adviceColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(adviceIcon, color: adviceColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      advice,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightStat(String title, String value, String sub, Color valColor) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valColor, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildInsightRow(IconData icon, String prefix, String bold, String suffix, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              children: [
                TextSpan(text: prefix),
                TextSpan(text: bold, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                TextSpan(text: suffix),
              ],
            ),
          ),
        ),
      ],
    );
  }
}