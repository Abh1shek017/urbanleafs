import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/balance_sheet_summary_model.dart';
import '../models/transaction_entry_model.dart';
import '../repositories/balance_sheet_repository.dart';
import 'cache_service.dart';

class BalanceSheetService {
  final BalanceSheetRepository _repository;
  final CacheService _cache;

  BalanceSheetService(this._repository, this._cache);

  Future<List<TransactionEntry>> getTransactions(DateTimeRange range) async {
    final cacheKey =
        'transactions_${range.start.millisecondsSinceEpoch}_${range.end.millisecondsSinceEpoch}';

    final cached = _cache.get<List<TransactionEntry>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    final transactions = await _repository.getTransactions(range);
    _cache.set(cacheKey, transactions, Duration(minutes: 3));

    return transactions;
  }

  Future<BalanceSheetSummary> calculateSummary(
    List<TransactionEntry> transactions,
    double totalDue,
    int dueCustomerCount,
  ) async {
    // Debug: Print transaction details
    print('=== Balance Sheet Debug ===');
    print('Total transactions: ${transactions.length}');

    final expenseTransactions = transactions
        .where((t) => t.type == 'expense')
        .toList();
    print('Expense transactions: ${expenseTransactions.length}');

    for (var exp in expenseTransactions) {
      print(
        'Expense: ${exp.description} - Amount: ${exp.amount} - Type: ${exp.itemType}',
      );
    }

    final totalSold = transactions
        .where((t) => t.type == 'sold')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final rawPurchases = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              (t.itemType?.toLowerCase() == 'raw material' ||
                  t.itemType?.toLowerCase() == 'raw' ||
                  t.itemType?.toLowerCase() == 'material'),
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    print('Calculated values:');
    print('- Total Sold: $totalSold');
    print('- Total Expenses: $totalExpenses');
    print('- Raw Purchases: $rawPurchases');
    print('=== End Debug ===');

    return BalanceSheetSummary(
      totalSold: totalSold,
      totalExpenses:
          totalExpenses - rawPurchases, // Exclude raw purchases from expenses
      rawPurchases: rawPurchases,
      totalDue: totalDue,
      dueCustomerCount: dueCustomerCount,
    );
  }

  void clearCache() {
    _cache.clear();
  }

  // Temporary debug method to check database structure
  Future<void> debugDatabaseStructure() async {
    print('=== Debugging Database Structure ===');

    // Check expenses collection
    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .limit(5)
        .get();
    print('Sample expenses:');
    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      print('Expense ID: ${doc.id}');
      print('  - description: ${data['description']}');
      print('  - amount: ${data['amount']}');
      print('  - type: ${data['type']}');
      print('  - date: ${data['date']}');
      print('  - addedAt: ${data['addedAt']}');
      print('---');
    }

    // Check orders collection
    final ordersSnapshot = await FirebaseFirestore.instance
        .collectionGroup('orders')
        .limit(5)
        .get();
    print('Sample orders:');
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      print('Order ID: ${doc.id}');
      print('  - customerName: ${data['customerName']}');
      print('  - totalAmount: ${data['totalAmount']}');
      print('  - orderTime: ${data['orderTime']}');
      print('---');
    }
  }
}
