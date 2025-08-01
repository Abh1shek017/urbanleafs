import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/transaction_entry_model.dart';
// import '../models/balance_sheet_summary_model.dart';

class BalanceSheetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TransactionEntry>> getTransactions(DateTimeRange range) async {
    try {
      final expenses = await _getExpenses(range);
      final orders = await _getOrders(range);

      final allTransactions = [...expenses, ...orders];
      allTransactions.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      return allTransactions;
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<List<TransactionEntry>> _getExpenses(DateTimeRange range) async {
    print('=== Fetching Expenses ===');
    print('Range: ${range.start} to ${range.end}');

    final snapshot = await _firestore
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    print('Found ${snapshot.docs.length} expense documents');

    final expenses = snapshot.docs
        .map((doc) => TransactionEntry.fromFirestore(doc))
        .toList();

    print('Converted to ${expenses.length} transaction entries');
    return expenses;
  }

  Future<List<TransactionEntry>> _getOrders(DateTimeRange range) async {
    final snapshot = await _firestore
        .collectionGroup('orders')
        .where(
          'orderTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
        )
        .where('orderTime', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    return snapshot.docs
        .map((doc) => TransactionEntry.fromFirestore(doc))
        .toList();
  }
}
