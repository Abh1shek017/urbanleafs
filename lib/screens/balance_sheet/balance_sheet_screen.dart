import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/balance_sheet_provider.dart';
import '../../models/balance_sheet_state.dart';
import '../../models/transaction_entry.dart';
import '../../repositories/customer_repository.dart';
import '../../providers/due_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // final int dueCustomerCount;
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  String dateFilter = 'All Dates';
  String? selectedMonthYear;
  String sortOption = 'Latest First';
  String paymentFilter = 'All';
  final paymentStatusOptions = ['All', 'Paid', 'Unpaid', 'Partially Paid'];
  // List of months for selection
  List<String> monthYearOptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForCurrentMonth();
      _generateMonthYearOptions();
    });
  }

  void _generateMonthYearOptions() {
    final now = DateTime.now();
    final List<String> options = [];
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      options.add(DateFormat('MMMM yyyy').format(date));
    }
    setState(() {
      monthYearOptions = options;
    });
  }

  void _loadDataForCurrentMonth() {
    final monthIndex = DateFormat('MMMM').parse(selectedMonth).month;
    final start = DateTime(selectedYear, monthIndex, 1);
    final end = DateTime(selectedYear, monthIndex + 1, 0, 23, 59, 59);
    ref
        .read(balanceSheetProvider.notifier)
        .loadData(
          range: DateTimeRange(start: start, end: end),
        );
  }

  void _loadDataForCustom(DateTimeRange range) {
    ref.read(balanceSheetProvider.notifier).loadData(range: range);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(balanceSheetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Balance Sheet')),
      body: Column(
        children: [
          Material(
            elevation: 2,
            child: _buildFilterSection(), // Fixed filter
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  setState(() {
                    _cardScale =
                        (1.0 - (scrollNotification.metrics.pixels / 200)).clamp(
                          0.85,
                          1.0,
                        );
                  });
                }
                return false;
              },
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
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
                    _buildTransactionList(state.transactions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyQuickFilter(String key) {
    final range = _getRangeFromQuickFilter(key);
    setState(() {
      customRange = range;
    });
    _loadDataForCustom(range);
  }

  DateTimeRange _getRangeFromQuickFilter(String key) {
    final now = DateTime.now();

    switch (key) {
      case 'this_month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: lastMonth,
          end: DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59),
        );
      case 'this_quarter':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, quarterStartMonth, 1),
          end: DateTime(now.year, quarterStartMonth + 3, 0, 23, 59, 59),
        );
      case 'half_year':
        final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
        return DateTimeRange(
          start: sixMonthsAgo,
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 'this_year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case 'last_year':
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year - 1, 12, 31, 23, 59, 59),
        );
      default:
        return DateTimeRange(start: now, end: now);
    }
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
                  final selectedMonthIndex = DateFormat(
                    'MMMM',
                  ).parse(val).month;
                  if (selectedYear == now.year &&
                      selectedMonthIndex > now.month) {
                    return;
                  }
                  setState(() {
                    selectedMonth = val;
                    customRange = null;
                  });
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
                final selectedMonthIndex = DateFormat(
                  'MMMM',
                ).parse(selectedMonth).month;
                if (val == now.year && selectedMonthIndex > now.month) {
                  setState(
                    () => selectedMonth = DateFormat('MMMM').format(now),
                  );
                }
                setState(() {
                  selectedYear = val;
                  customRange = null;
                });
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
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: _applyQuickFilter,
            icon: const Icon(Icons.filter_alt_outlined),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'this_month',
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: 'last_month',
                child: Text('Last Month'),
              ),
              const PopupMenuItem(
                value: 'this_quarter',
                child: Text('This Quarter'),
              ),
              const PopupMenuItem(
                value: 'half_year',
                child: Text('Last 6 Months'),
              ),
              const PopupMenuItem(value: 'this_year', child: Text('This Year')),
              const PopupMenuItem(value: 'last_year', child: Text('Last Year')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BalanceSheetState state) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              FutureBuilder<double>(
                future: _calculateTotalSold(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSummaryCard(
                      'Total Sold',
                      'Loading...',
                      Colors.green[300]!,
                      () {},
                    );
                  } else if (snapshot.hasError) {
                    return _buildSummaryCard(
                      'Total Sold',
                      'Error',
                      Colors.green[300]!,
                      () {},
                    );
                  } else {
                    final total = snapshot.data ?? 0.0;
                    return _buildSummaryCard(
                      'Total Sold',
                      '₹${total.toStringAsFixed(2)}',
                      Colors.green[300]!,
                      () => _showTotalSoldDetails(context),
                    );
                  }
                },
              ),

              _buildSummaryCard(
                'Total Expenses',
                '₹${state.totalExpenses.toStringAsFixed(2)}',
                Colors.red[300]!,
                () => _showTotalExpensesDetails(context, excludeRaw: true),
              ),
              _buildSummaryCard(
                'Raw Purchases',
                '₹${state.rawPurchases.toStringAsFixed(2)}',
                Colors.grey[400]!,
                () => _showRawPurchasesDetails(context),
              ),
            ],
          ),
          SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final dueAsync = ref.watch(allCustomersWithDueProvider);

              return dueAsync.when(
                loading: () => _buildSummaryCard(
                  'Due Amounts',
                  'Loading…',
                  Colors.orange[400]!,
                  () => _showDueCustomersBottomSheet(context),
                ),
                error: (e, _) => _buildSummaryCard(
                  'Due Amounts',
                  'Error',
                  Colors.orange[400]!,
                  () => _showDueCustomersBottomSheet(context),
                ),
                data: (customers) {
                  final totalDue = customers.fold<double>(
                    0,
                    (sum, c) => sum + c.totalDue,
                  );
                  final count = customers.length;

                  return _buildSummaryCard(
                    'Due Amounts',
                    '₹${totalDue.toStringAsFixed(2)} from $count Customers',
                    Colors.orange[400]!,
                    () => _showDueCustomersBottomSheet(context),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    VoidCallback onTap,
  ) {
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
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(amount, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionEntry> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No transactions found for this period.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final bgColor = tx.type == 'sold'
            ? const Color.fromARGB(255, 78, 184, 81) // Greenish for sales
            : const Color.fromARGB(255, 176, 57, 10); // Reddish for expenses

        return GestureDetector(
          onTap: () =>
              _showTransactionDetail(context, tx), // 👈 shows full info on tap
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.type == 'sold'
                      ? 'Customer: ${tx.description}' // 👈 stored as description
                      : 'Expense: ${tx.description}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '₹${tx.amount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (tx.type == 'sold')
                  Text(
                    'Item Type: ${tx.itemType ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                Text(
                  'Date: ${dateFormat.format(tx.addedAt)}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Type: ${tx.type.toUpperCase()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetail(BuildContext context, TransactionEntry tx) {
    final isExpense = tx.type == 'expense';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tx.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${tx.amount.toStringAsFixed(2)}'),
            if (tx.itemType != null) Text('Item Type: ${tx.itemType}'),
            Text('Type: ${isExpense ? 'Expense' : 'Sold'}'),
            Text('Date: ${dateFormat.format(tx.addedAt)}'),
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

  void _showDataSheet<T>(
    BuildContext context,
    String title,
    List<T> data,
    Widget Function(T) itemBuilder,
  ) {
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  Future<List<TransactionEntry>> fetchAllTransactions() async {
    final range = _getSelectedRange();

    // Fetch expenses
    final expenseSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .where(
          'addedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
        )
        .where('addedAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    final expenses = expenseSnap.docs.map((doc) {
      final d = doc.data();
      return TransactionEntry(
        id: doc.id,
        type: 'expense',
        description: d['description'] ?? '',
        amount: (d['amount'] ?? 0).toDouble(),
        addedAt: (d['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });

    // Fetch orders
    final orderSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where(
          'orderTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
        )
        .where('orderTime', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    final orders = orderSnap.docs.map((doc) {
      final d = doc.data();
      return TransactionEntry(
        id: doc.id,
        type: 'sold',
        description: d['customerName'] ?? 'Unknown',
        amount: (d['totalAmount'] ?? 0).toDouble(),
        addedAt: (d['orderTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        itemType: d['itemType'] ?? 'Unknown',
      );
    });

    // Merge & sort
    final allTransactions = [...expenses, ...orders].toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt)); // latest first

    return allTransactions;
  }

  Future<List<Map<String, dynamic>>> _fetchOrdersForPeriod() async {
    final range = _getSelectedRange();

    final snap = await FirebaseFirestore.instance
        .collectionGroup('orders') // 🔥 Query all 'orders' subcollections
        .where(
          'orderTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
        )
        .where('orderTime', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    final list = snap.docs.map((doc) {
      final d = doc.data();
      return {
        'id': doc.id,
        'totalSold': (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
        'customerName': d['customerName'] ?? 'Unknown',
        'orderTime': (d['orderTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'itemType': d['item'] ?? 'Unknown',
      };
    }).toList();

    return list.reversed.toList();
  }

  Future<double> _calculateTotalSold() async {
    final repo = CustomerRepository();
    return await repo.getTotalSoldAcrossAllCustomers();
  }

  Future<List<Map<String, dynamic>>> _fetchExpensesForPeriod({
    String? filterType,
  }) async {
    final range = _getSelectedRange();
    Query q = FirebaseFirestore.instance
        .collection('expenses')
        .where(
          'addedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
        )
        .where('addedAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end));

    if (filterType != null) {
      q = q.where('type', isEqualTo: filterType);
    }

    final snap = await q.get();

    final expensesList = snap.docs.map((doc) {
      final d = (doc.data() as Map<String, dynamic>?) ?? {};
      return {
        'description': d['description'] ?? '',
        'amount': (d['amount'] ?? 0).toDouble(),
        'type': d['type'] ?? '',
        'addedAt': (d['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();

    return expensesList.reversed.toList();
  }

  Future<List<Map<String, dynamic>>> fetchCustomerDueOrders(
    String customerId,
  ) async {
    final ordersSnap = await FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .collection('orders')
        .get();

    List<Map<String, dynamic>> dueOrders = [];

    for (final doc in ordersSnap.docs) {
      final data = doc.data();
      final total = (data['totalAmount'] ?? 0).toDouble();
      final paid = (data['amountPaid'] ?? 0).toDouble();
      final due = total - paid;

      if (due > 0) {
        dueOrders.add({
          'item': data['itemName'] ?? 'Unknown',
          'date': (data['orderTime'] as Timestamp?)?.toDate(),
          'totalAmount': total,
          'amountPaid': paid,
          'dueAmount': due,
        });
      }
    }

    return dueOrders;
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
        double amount = 0.0;
        final rawAmount = order['totalSold'] ?? order['totalAmount'] ?? 0.0;

        if (rawAmount is int) {
          amount = rawAmount.toDouble();
        } else if (rawAmount is double) {
          amount = rawAmount;
        } else if (rawAmount is String) {
          amount = double.tryParse(rawAmount) ?? 0.0;
        }

        final customer = order['customerName']?.toString() ?? 'Unknown';

        DateTime? orderDate;
        if (order['orderTime'] is Timestamp) {
          orderDate = (order['orderTime'] as Timestamp).toDate();
        } else if (order['orderTime'] is DateTime) {
          orderDate = order['orderTime'];
        }

        final date = orderDate != null
            ? dateFormat.format(orderDate)
            : 'Unknown';

        final id = order['id']?.toString() ?? '';
        final shortId = id.length >= 6 ? id.substring(0, 6) : id;

        return Container(
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ListTile(
            title: Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Customer: $customer\nDate: $date',
                style: const TextStyle(height: 1.4),
              ),
            ),
            trailing: Text(
              '#$shortId',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
        );
      });
    }
  }

  void _showTotalExpensesDetails(
    BuildContext context, {
    bool excludeRaw = false,
  }) async {
    final expenses = await _fetchExpensesForPeriod();

    // Optionally filter out raw purchases
    final filteredExpenses = excludeRaw
        ? expenses
              .where((e) => e['type'].toLowerCase() != 'raw material')
              .toList()
        : expenses;

    if (context.mounted) {
      _showDataSheet(context, 'Total Expenses Details', filteredExpenses, (
        exp,
      ) {
        final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
        final type = exp['type'] ?? 'N/A';
        final addedAt = exp['addedAt'] as DateTime?;
        final date = addedAt != null ? dateFormat.format(addedAt) : 'Unknown';

        return Container(
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ListTile(
            title: Text(
              exp['description'] ?? 'No Description',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Amount: ₹${amount.toStringAsFixed(2)}\n'
                'Type: $type\n'
                'Date: $date',
                style: const TextStyle(height: 1.4),
              ),
            ),
          ),
        );
      });
    }
  }

  void _showDueCustomersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Customers with Outstanding Dues',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final allCustomersAsync = ref.watch(
                          allCustomersWithDueProvider,
                        );

                        return allCustomersAsync.when(
                          data: (customers) {
                            if (customers.isEmpty) {
                              return const Center(
                                child: Text('No customers found.'),
                              );
                            }
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: customers.length,
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                final due = customer.totalDue;
                                final cardColor = due <= 0
                                    ? Colors.grey[100]
                                    : due < 1000
                                    ? Colors.green[100]
                                    : due < 0
                                    ? Colors.orange[100]
                                    : Colors.red[100];

                                return Card(
                                  color: cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading:
                                        customer.profileImageUrl?.isNotEmpty ==
                                            true
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              customer.profileImageUrl!,
                                            ),
                                          )
                                        : const CircleAvatar(
                                            child: Icon(Icons.person),
                                          ),
                                    title: Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '📞 ${customer.phone}\n🏠 ${customer.address}',
                                    ),
                                    isThreeLine: true,
                                    trailing: Text(
                                      '₹${due.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap: () {
                                      _showCustomerDetailBottomSheet(
                                        context,
                                        customer,
                                        customer.payments,
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(child: Text('Error: $err')),
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

  // Helper to safely get DateTime from orderTime
  DateTime getOrderTime(dynamic orderTime) {
    if (orderTime is Timestamp) {
      return orderTime.toDate();
    } else if (orderTime is DateTime) {
      return orderTime;
    } else {
      return DateTime.now(); // fallback
    }
  }

  void _showCustomerDetailBottomSheet(
    BuildContext context,
    dynamic customer,
    List<Map<String, dynamic>> payments,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (Context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            String? selectedYear;
            String? selectedMonth;
            String paymentFilter = 'All';
            String sortOption = 'Latest First';

            final List<String> yearOptions = ['2024', '2025'];
            final List<String> monthOptions = [
              'January',
              'February',
              'March',
              'April',
              'May',
              'June',
              'July',
              'August',
              'September',
              'October',
              'November',
              'December',
            ];

            final List<String> paymentStatusOptions = [
              'All',
              'Paid',
              'Unpaid',
              'Partially Paid',
            ];

            List<Map<String, dynamic>> allOrders = [...customer.allOrders];
            List<Map<String, dynamic>> filteredOrders = [...allOrders];

            double totalAmount = 0;
            double totalPaid = 0;
            double totalDue = 0;

            void applyFilters() {
              filteredOrders = [...customer.allOrders];

              if (selectedYear != null && selectedMonth != null) {
                filteredOrders = filteredOrders.where((order) {
                  final orderDate = getOrderTime(order['orderTime']);
                  return orderDate.year.toString() == selectedYear &&
                      orderDate.month ==
                          (monthOptions.indexOf(selectedMonth!) + 1);
                }).toList();
              }

              if (paymentFilter != 'All') {
                filteredOrders = filteredOrders.where((order) {
                  final status = (order['paymentStatus'] ?? '')
                      .toString()
                      .toLowerCase();
                  return status == paymentFilter.toLowerCase();
                }).toList();
              }

              filteredOrders.sort((a, b) {
                final aTime = getOrderTime(a['orderTime']);
                final bTime = getOrderTime(b['orderTime']);
                return sortOption == 'Latest First'
                    ? bTime.compareTo(aTime)
                    : aTime.compareTo(bTime);
              });

              totalAmount = 0;
              totalPaid = 0;
              for (var order in filteredOrders) {
                totalAmount += (order['totalAmount'] ?? 0).toDouble();
              }
              totalPaid = payments.fold(
                0.0,
                (sum, payment) => sum + ((payment['amount'] ?? 0).toDouble()),
              );
              totalDue = totalAmount - totalPaid;
            }

            applyFilters();

            return StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          Center(
                            child: customer.profileImageUrl?.isNotEmpty == true
                                ? CircleAvatar(
                                    radius: 40,
                                    backgroundImage: NetworkImage(
                                      customer.profileImageUrl!,
                                    ),
                                  )
                                : const CircleAvatar(
                                    radius: 40,
                                    child: Icon(Icons.person, size: 40),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final Uri phoneUri = Uri(
                                    scheme: 'tel',
                                    path: customer.phone,
                                  );
                                  if (await canLaunchUrl(phoneUri)) {
                                    await launchUrl(phoneUri);
                                  }
                                },
                                child: Text(
                                  "📞 ${customer.phone}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueAccent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "🏠 ${customer.address}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              DropdownButton<String>(
                                hint: const Text("Select Year"),
                                value: selectedYear,
                                items: yearOptions.map((year) {
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedYear = value;
                                    selectedMonth = null;
                                    applyFilters();
                                  });
                                },
                              ),
                              if (selectedYear != null)
                                DropdownButton<String>(
                                  hint: const Text("Select Month"),
                                  value: selectedMonth,
                                  items: monthOptions.map((month) {
                                    return DropdownMenuItem(
                                      value: month,
                                      child: Text(month),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedMonth = value;
                                      applyFilters();
                                    });
                                  },
                                ),
                              DropdownButton<String>(
                                value: sortOption,
                                items: ['Latest First', 'Oldest First'].map((
                                  option,
                                ) {
                                  return DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    sortOption = value!;
                                    applyFilters();
                                  });
                                },
                              ),
                              DropdownButton<String>(
                                value: paymentFilter,
                                items: paymentStatusOptions.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    paymentFilter = value!;
                                    applyFilters();
                                  });
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.clear),
                                label: const Text("Clear Filters"),
                                onPressed: () {
                                  setState(() {
                                    selectedYear = null;
                                    selectedMonth = null;
                                    paymentFilter = 'All';
                                    sortOption = 'Latest First';
                                    applyFilters();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceAround,
                            children: [
                              Text(
                                '🧾 Total: ₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '✅ Paid: ₹${totalPaid.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                              Text(
                                '❌ Due: ₹${totalDue.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              labelColor: Colors.blue,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.blue,
                              tabs: [
                                Tab(text: 'Orders'),
                                Tab(text: 'Payments'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  ListView.builder(
                                    controller: scrollController,
                                    itemCount: filteredOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = filteredOrders[index];
                                      final orderTime = getOrderTime(
                                        order['orderTime'],
                                      );
                                      final paid = (order['amountPaid'] ?? 0)
                                          .toDouble();
                                      final total = (order['totalAmount'] ?? 0)
                                          .toDouble();
                                      final due = total - paid;
                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            '₹${total.toStringAsFixed(2)}',
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Paid: ₹${paid.toStringAsFixed(2)}',
                                              ),
                                              Text(
                                                'Due: ₹${due.toStringAsFixed(2)}',
                                              ),
                                              Text(
                                                DateFormat(
                                                  'dd MMM yyyy',
                                                ).format(orderTime),
                                              ),
                                              Text(
                                                'Status: ${order['paymentStatus'] ?? 'Unknown'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  payments.isEmpty
                                      ? const Center(
                                          child: Text('No payments found.'),
                                        )
                                      : (() {
                                          payments.sort((a, b) {
                                            final tsA =
                                                a['receivedTime'] ??
                                                a['timestamp'];
                                            final tsB =
                                                b['receivedTime'] ??
                                                b['timestamp'];

                                            final dateA = tsA is Timestamp
                                                ? tsA.toDate()
                                                : (tsA is DateTime
                                                      ? tsA
                                                      : DateTime.now());
                                            final dateB = tsB is Timestamp
                                                ? tsB.toDate()
                                                : (tsB is DateTime
                                                      ? tsB
                                                      : DateTime.now());

                                            return dateB.compareTo(
                                              dateA,
                                            ); // Descending order
                                          });

                                          return ListView.builder(
                                            controller: scrollController,
                                            itemCount: payments.length,
                                            itemBuilder: (context, index) {
                                              final payment = payments[index];
                                              final amount =
                                                  (payment['amount'] ?? 0)
                                                      .toDouble();
                                              final note = payment['note'];
                                              final receiver =
                                                  payment['receivedBy'] ??
                                                  'Unknown';
                                              final timestamp =
                                                  payment['receivedTime'] ??
                                                  payment['timestamp'];
                                              final receivedTime =
                                                  timestamp is Timestamp
                                                  ? timestamp.toDate()
                                                  : (timestamp is DateTime
                                                        ? timestamp
                                                        : DateTime.now());
                                              final isAutoPayment =
                                                  note != null &&
                                                  note.toString().isNotEmpty;

                                              return Card(
                                                child: ListTile(
                                                  leading: Icon(
                                                    isAutoPayment
                                                        ? Icons.flash_on
                                                        : Icons.payments,
                                                    color: isAutoPayment
                                                        ? Colors.orange
                                                        : Colors.blue,
                                                  ),
                                                  title: Text(
                                                    '₹${amount.toStringAsFixed(2)}',
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Received by: $receiver',
                                                      ),
                                                      Text(
                                                        isAutoPayment
                                                            ? 'Note: $note'
                                                            : 'Manual payment',
                                                      ),
                                                      Text(
                                                        'Date: ${DateFormat('dd MMM yyyy – hh:mm a').format(receivedTime)}',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        })(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showRawPurchasesDetails(BuildContext context) async {
    final expenses = await _fetchExpensesForPeriod(filterType: 'Raw Material');

    // Sort by addedAt descending
    expenses.sort((a, b) {
      final dateA = a['addedAt'] as DateTime?;
      final dateB = b['addedAt'] as DateTime?;
      return dateB?.compareTo(dateA ?? DateTime(0)) ?? 0;
    });

    if (context.mounted) {
      _showDataSheet(context, 'Raw Purchases Details', expenses, (exp) {
        final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
        final desc = exp['description'] ?? 'Unknown';
        final date = (exp['addedAt'] is DateTime)
            ? dateFormat.format(exp['addedAt'])
            : 'Unknown';

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[350],
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ListTile(
            title: Text(
              desc,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '₹${amount.toStringAsFixed(2)}\nDate: $date',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        );
      });
    }
  }
}
