import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/balance_sheet_state.dart';
import '../models/expense_model.dart';
import '../models/transaction_entry.dart';
class BalanceSheetViewModel extends StateNotifier<BalanceSheetState> {
  BalanceSheetViewModel() : super(BalanceSheetState(dueCustomerCount: 0));

  Future<void> loadData({required DateTimeRange range}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final firestore = FirebaseFirestore.instance;
      final start = Timestamp.fromDate(range.start);
      final end = Timestamp.fromDate(range.end);

      final ordersSnap = await firestore
          .collection('orders')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .get();

      final expensesSnap = await firestore
          .collection('expenses')
          .where('addedAt', isGreaterThanOrEqualTo: start)
          .where('addedAt', isLessThanOrEqualTo: end)
          .get();

      final duesSnap = await firestore.collection('dues').get();

      double totalSold = 0;
      double totalExpenses = 0;
      double totalProfit = 0;
      double dueAmounts = 0;
      double rawPurchases = 0;
      int dueCustomerCount = 0;

      final List<TransactionEntry> transactions = [];
      final List<ExpenseModel> expenses = [];

      // Process orders (sales)
      for (var doc in ordersSnap.docs) {
        final data = doc.data();
        final double amount = (data['totalAmount'] ?? 0).toDouble();
        final DateTime date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();

        totalSold += amount;

        transactions.add(TransactionEntry(
          id: doc.id,
          type: 'sold',
          description: data['customerName'] ?? 'Unknown',
          amount: amount,
          addedAt: date,
          itemType: data['itemType'] ?? 'Unknown',
        ));
      }

      // Process expenses
      for (var doc in expensesSnap.docs) {
        final exp = ExpenseModel.fromSnapshot(doc);
        expenses.add(exp);

        final normalizedType = exp.type.trim().toLowerCase();
        if (normalizedType == 'raw material') {
          rawPurchases += exp.amount;
        } else {
          totalExpenses += exp.amount;
        }

        transactions.add(TransactionEntry(
          id: exp.id,
          type: 'expense',
          description: exp.description,
          amount: exp.amount,
          addedAt: exp.addedAt,
        ));
      }

      // Process dues
      for (var doc in duesSnap.docs) {
        final data = doc.data();
        final double amount = (data['amount'] ?? 0).toDouble();
        if (amount > 0) {
          dueAmounts += amount;
          dueCustomerCount++;
        }
      }

      // Compute final profit
      totalProfit = totalSold - totalExpenses;

      // Sort transactions by newest first
      transactions.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      // Final state update
      state = state.copyWith(
        isLoading: false,
        totalSold: totalSold,
        totalExpenses: totalExpenses,
        totalProfit: totalProfit,
        dueAmounts: dueAmounts,
        rawPurchases: rawPurchases,
        dueCustomerCount: dueCustomerCount,
        transactions: transactions,
        expenses: expenses,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
