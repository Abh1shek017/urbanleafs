import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/balance_sheet_provider.dart';

class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends ConsumerState<BalanceSheetScreen> {
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int selectedYear = DateTime.now().year;
  DateTimeRange? customRange;
  double _cardScale = 1.0;
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForCurrentMonth();
    });
  }

  void _loadDataForCurrentMonth() {
    final monthIndex = DateFormat('MMMM').parse(selectedMonth).month;
    final start = DateTime(selectedYear, monthIndex, 1);
    final end = DateTime(selectedYear, monthIndex + 1, 0, 23, 59, 59);
    ref.read(balanceSheetViewModelProvider.notifier).loadData(
      range: DateTimeRange(start: start, end: end),
    );
  }

  void _loadDataForCustom(DateTimeRange range) {
    ref.read(balanceSheetViewModelProvider.notifier).loadData(range: range);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(balanceSheetViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Balance Sheet')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            setState(() {
              _cardScale = (1.0 - (scrollNotification.metrics.pixels / 200))
                  .clamp(0.85, 1.0);
            });
          }
          return false;
        },
        child: ListView(
          children: [
            _buildFilterSection(),
            Transform(
  transform: Matrix4.identity()..scale(1.0, _cardScale),
  alignment: Alignment.topCenter,
  child: _buildSummaryGrid(state),
),

            const Divider(),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('Error: ${state.error}')),
              )
            else
              _buildTransactionList(state.expenses),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: selectedMonth,
              isExpanded: true,
              items: List.generate(12, (index) {
                final month = DateFormat('MMMM').format(DateTime(0, index + 1));
                return DropdownMenuItem(value: month, child: Text(month));
              }),
              onChanged: (val) {
                if (val != null) {
                  final now = DateTime.now();
                  final selectedMonthIndex =
                      DateFormat('MMMM').parse(val).month;
                  if (selectedYear == now.year &&
                      selectedMonthIndex > now.month) {
                    return;
                  }
                  setState(() => selectedMonth = val);
                  _loadDataForCurrentMonth();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: selectedYear,
            items: List.generate(5, (i) {
              final year = DateTime.now().year - i;
              return DropdownMenuItem(value: year, child: Text('$year'));
            }),
            onChanged: (val) {
              if (val != null) {
                final now = DateTime.now();
                final selectedMonthIndex =
                    DateFormat('MMMM').parse(selectedMonth).month;
                if (val == now.year && selectedMonthIndex > now.month) {
                  setState(() =>
                      selectedMonth = DateFormat('MMMM').format(now));
                }
                setState(() => selectedYear = val);
                _loadDataForCurrentMonth();
              }
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => customRange = picked);
                _loadDataForCustom(picked);
              }
            },
            child: const Text('Custom Range'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BalanceSheetState state) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _buildSummaryCard('Total Sold',
              '₹${state.totalSold.toStringAsFixed(2)}', Colors.green[100]!, () {
            _showTotalSoldDetails(context);
          }),
          _buildSummaryCard(
              'Total Expenses',
              '₹${state.totalExpenses.toStringAsFixed(2)}',
              Colors.red[100]!, () {
            _showTotalExpensesDetails(context);
          }),
          _buildSummaryCard(
              'Total Profit',
              '₹${state.totalProfit.toStringAsFixed(2)}',
              Colors.blue[100]!, () {
            _showProfitDetails(
              context,
              state.totalSold,
              state.totalExpenses,
              state.totalProfit,
            );
          }),
          _buildSummaryCard(
              'Due Amounts',
              '₹${state.dueAmounts.toStringAsFixed(2)}',
              Colors.orange[100]!, () {
            _showDueAmountsDetails(context);
          }),
          _buildSummaryCard(
              'Raw Purchases',
              '₹${state.rawPurchases.toStringAsFixed(2)}',
              Colors.grey[300]!, () {
            _showRawPurchasesDetails(context);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String amount, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text(amount, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('No transactions found for this period.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final bgColor = _getBgColor(exp.type);
        return GestureDetector(
          onTap: () => _showTransactionDetail(context, exp),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.description,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${exp.amount.toStringAsFixed(2)}'),
                Text('Type: ${exp.type}'),
                Text('Added: ${dateFormat.format(exp.addedAt)}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBgColor(String type) {
    switch (type) {
      case 'rawMaterial':
        return Colors.grey[200]!;
      case 'labor':
      case 'transportation':
      case 'other':
        return Colors.red[50]!;
      default:
        return Colors.green[50]!;
    }
  }

  void _showTransactionDetail(BuildContext context, ExpenseModel exp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(exp.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${exp.amount.toStringAsFixed(2)}'),
            Text('Type: ${exp.type}'),
            Text('Added: ${dateFormat.format(exp.addedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataSheet<T>(BuildContext context, String title, List<T> data,
      Widget Function(T) itemBuilder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: data.isEmpty
                    ? const Center(
                        child: Text('No records found for this period.'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: data.length,
                        itemBuilder: (context, index) =>
                            itemBuilder(data[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOrdersForPeriod() async {
    final range = _getSelectedRange();
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('orderTime', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .where('orderTime', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .get();

    return snap.docs.map((doc) {
      final d = (doc.data() as Map<String, dynamic>?) ?? {};
      return {
        'id': doc.id,
        'amount': (d['totalAmount'] ?? 0).toDouble(),
        'customer': d['customerName'] ?? 'N/A',
        'date': (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchExpensesForPeriod({String? filterType}) async {
    final range = _getSelectedRange();
    Query q = FirebaseFirestore.instance
        .collection('expenses')
        .where('addedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('addedAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end));
    if (filterType != null) q = q.where('type', isEqualTo: filterType);

    final snap = await q.get();
    return snap.docs.map((doc) {
      final d = (doc.data() as Map<String, dynamic>?) ?? {};
      return {
        'description': d['description'] ?? '',
        'amount': (d['amount'] ?? 0).toDouble(),
        'type': d['type'] ?? '',
        'addedAt': (d['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchDueOrdersForPeriod() async {
    final range = _getSelectedRange();
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('dueAmount', isGreaterThan: 0)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    return snap.docs.map((doc) {
      final d = (doc.data() as Map<String, dynamic>?) ?? {};
      return {
        'dueAmount': (d['dueAmount'] ?? 0).toDouble(),
        'customer': d['customerName'] ?? 'N/A',
        'date': (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  DateTimeRange _getSelectedRange() {
    final monthIndex = DateFormat('MMMM').parse(selectedMonth).month;
    final start = DateTime(selectedYear, monthIndex, 1);
    final end = DateTime(selectedYear, monthIndex + 1, 0, 23, 59, 59);
    return customRange ?? DateTimeRange(start: start, end: end);
  }

  void _showTotalSoldDetails(BuildContext context) async {
    final orders = await _fetchOrdersForPeriod();
    if (context.mounted) {
      _showDataSheet(context, 'Total Sold Details', orders, (order) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('₹${order['amount'].toStringAsFixed(2)}'),
            subtitle: Text('Customer: ${order['customer']}\n'
                'Date: ${dateFormat.format(order['date'])}'),
            trailing: Text('#${order['id'].substring(0, 6)}'),
          ),
        );
      });
    }
  }

  void _showTotalExpensesDetails(BuildContext context) async {
    final expenses = await _fetchExpensesForPeriod();
    if (context.mounted) {
      _showDataSheet(context, 'Total Expenses Details', expenses, (exp) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(exp['description']),
            subtitle: Text(
              '₹${exp['amount'].toStringAsFixed(2)}\n'
              'Type: ${exp['type']}\n'
              'Date: ${dateFormat.format(exp['addedAt'])}',
            ),
          ),
        );
      });
    }
  }

  void _showProfitDetails(
      BuildContext context, double sold, double expenses, double profit) {
    _showDataSheet(
      context,
      'Profit Calculation',
      [
        {'sold': sold, 'expenses': expenses, 'profit': profit},
      ],
      (data) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Sold: ₹${sold.toStringAsFixed(2)}'),
              Text('Total Expenses: ₹${expenses.toStringAsFixed(2)}'),
              const Divider(),
              Text('Total Profit: ₹${profit.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  void _showDueAmountsDetails(BuildContext context) async {
    final dues = await _fetchDueOrdersForPeriod();
    if (context.mounted) {
      _showDataSheet(context, 'Due Amounts Details', dues, (order) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('₹${order['dueAmount'].toStringAsFixed(2)}'),
            subtitle: Text('Customer: ${order['customer']}\n'
                'Date: ${dateFormat.format(order['date'])}'),
          ),
        );
      });
    }
  }

  void _showRawPurchasesDetails(BuildContext context) async {
    final expenses = await _fetchExpensesForPeriod(filterType: 'rawMaterial');
    if (context.mounted) {
      _showDataSheet(context, 'Raw Purchases Details', expenses, (exp) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(exp['description']),
            subtitle: Text(
              '₹${exp['amount'].toStringAsFixed(2)}\n'
              'Date: ${dateFormat.format(exp['addedAt'])}',
            ),
          ),
        );
      });
    }
  }
}
