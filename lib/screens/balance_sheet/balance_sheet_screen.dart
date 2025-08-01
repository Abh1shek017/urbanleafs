import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the models and providers
import '../../models/transaction_entry_model.dart';
import '../../providers/balance_sheet_provider.dart';
import '../../providers/due_provider.dart';
import '../../repositories/customer_repository.dart';

// Import the new modular widgets
import '../../widgets/balance_sheet/filter_section.dart';
import '../../widgets/balance_sheet/summary_grid.dart';
import '../../widgets/balance_sheet/transaction_list.dart';
import '../../widgets/common/error_handler.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/balance_sheet/customer_detail_sheet.dart';

class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends ConsumerState<BalanceSheetScreen> {
  // State for the filter UI components
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int _selectedYear = DateTime.now().year;
  DateTimeRange? _customRange;
  double _cardScale = 1.0;

  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final range = _getSelectedRange();
    ref.read(balanceSheetProvider.notifier).loadData(range: range);
  }

  Future<void> _refreshData() async {
    try {
      final range = _getSelectedRange();
      await ref.read(balanceSheetProvider.notifier).loadData(range: range);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data refreshed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        final error = ErrorHandler.fromException(e);
        ErrorHandler.showSnackBar(context, error);
      }
    }
  }

  DateTimeRange _getSelectedRange() {
    if (_customRange != null) {
      return _customRange!;
    }
    final monthIndex = DateFormat('MMMM').parse(_selectedMonth).month;
    final start = DateTime(_selectedYear, monthIndex, 1);
    final end = DateTime(_selectedYear, monthIndex + 1, 0, 23, 59, 59);
    return DateTimeRange(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(balanceSheetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Sheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        message: 'Loading balance sheet data...',
        child: Column(
          children: [
            // Filter Section
            Material(
              elevation: 2,
              child: FilterSection(
                selectedMonth: _selectedMonth,
                selectedYear: _selectedYear,
                customRange: _customRange,
                onMonthChanged: (month) {
                  setState(() {
                    _selectedMonth = month;
                    _customRange = null;
                  });
                  _loadData();
                },
                onYearChanged: (year) {
                  setState(() {
                    _selectedYear = year;
                    _customRange = null;
                  });
                  _loadData();
                },
                onCustomRangeSelected: (range) {
                  setState(() {
                    _customRange = range;
                  });
                  _loadData();
                },
                onQuickFilterSelected: (key) {
                  final range = _getRangeFromQuickFilter(key);
                  setState(() => _customRange = range);
                  _loadData();
                },
              ),
            ),
            
            // Main Content
            Expanded(
              child: state.error != null
                  ? ErrorHandler.buildErrorWidget(
                      ErrorHandler.fromException(state.error!),
                      onRetry: _refreshData,
                    )
                  : NotificationListener<ScrollNotification>(
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
                        padding: const EdgeInsets.only(top: 8),
                        children: [
                          // Summary Grid
                          SummaryGrid(
                            state: state,
                            cardScale: _cardScale,
                            onTotalSoldTap: () => _showTotalSoldDetails(context),
                            onTotalExpensesTap: () => _showTotalExpensesDetails(context),
                            onRawPurchasesTap: () => _showRawPurchasesDetails(context),
                            onDueAmountsTap: () => _showDueCustomersBottomSheet(context),
                          ),
                          
                          const Divider(),
                          
                          // Transaction List
                          if (state.isLoading)
                            const LoadingWidget(
                              message: 'Loading transactions...',
                              type: LoadingType.circular,
                            )
                          else
                            TransactionList(
                              transactions: state.transactions,
                              onTransactionTap: _showTransactionDetail,
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
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
            Text('Date: ${_dateFormat.format(tx.addedAt)}'),
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
                        itemBuilder: (context, index) => itemBuilder(data[index]),
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
        .collectionGroup('orders')
        .where('orderTime', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
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
    try {
      final repo = CustomerRepository();
      return await repo.getTotalSoldAcrossAllCustomers();
    } catch (e) {
      if (mounted) {
        final error = ErrorHandler.fromException(e);
        ErrorHandler.showSnackBar(context, error);
      }
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchExpensesForPeriod({String? filterType}) async {
    final range = _getSelectedRange();
    Query q = FirebaseFirestore.instance
        .collection('expenses')
        .where('addedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
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

  void _showTotalSoldDetails(BuildContext context) async {
    try {
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

          final date = orderDate != null ? _dateFormat.format(orderDate) : 'Unknown';
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
    } catch (e) {
      if (mounted) {
        final error = ErrorHandler.fromException(e);
        ErrorHandler.showSnackBar(context, error);
      }
    }
  }

  void _showTotalExpensesDetails(BuildContext context, {bool excludeRaw = true}) async {
    try {
      final expenses = await _fetchExpensesForPeriod();
      final filteredExpenses = excludeRaw
          ? expenses.where((e) => e['type'].toLowerCase() != 'raw material').toList()
          : expenses;

      if (context.mounted) {
        _showDataSheet(context, 'Total Expenses Details', filteredExpenses, (exp) {
          final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
          final type = exp['type'] ?? 'N/A';
          final addedAt = exp['addedAt'] as DateTime?;
          final date = addedAt != null ? _dateFormat.format(addedAt) : 'Unknown';

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
    } catch (e) {
      if (mounted) {
        final error = ErrorHandler.fromException(e);
        ErrorHandler.showSnackBar(context, error);
      }
    }
  }

  void _showRawPurchasesDetails(BuildContext context) async {
    try {
      final expenses = await _fetchExpensesForPeriod(filterType: 'Raw Material');
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
              ? _dateFormat.format(exp['addedAt'])
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
    } catch (e) {
      if (mounted) {
        final error = ErrorHandler.fromException(e);
        ErrorHandler.showSnackBar(context, error);
      }
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
                        final allCustomersAsync = ref.watch(allCustomersWithDueProvider);

                        return allCustomersAsync.when(
                          data: (customers) {
                            if (customers.isEmpty) {
                              return const Center(child: Text('No customers found.'));
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
                                        : due < 5000
                                            ? Colors.orange[100]
                                            : Colors.red[100];

                                return Card(
                                  color: cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: customer.profileImageUrl?.isNotEmpty == true
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(customer.profileImageUrl!),
                                          )
                                        : const CircleAvatar(child: Icon(Icons.person)),
                                    title: Text(
                                      customer.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                                      showCustomerDetailBottomSheet(
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
                          loading: () => const Center(child: CircularProgressIndicator()),
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
}