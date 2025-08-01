import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/balance_sheet_state.dart';
import '../models/expense_model.dart';
import '../models/transaction_entry_model.dart';
import '../../providers/customer_provider.dart';
import '../../models/balance_sheet_summary_model.dart';

class BalanceSheetViewModel extends StateNotifier<BalanceSheetState> {
  final Ref ref;

  BalanceSheetViewModel(this.ref)
    : super(BalanceSheetState());

  Future<void> loadData({required DateTimeRange range}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final firestore = FirebaseFirestore.instance;
      final start = Timestamp.fromDate(range.start);
      final end = Timestamp.fromDate(range.end);
      final ordersSnap = await firestore
          .collectionGroup('orders')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .get();

      final expensesSnap = await firestore
          .collection('expenses')
          .where('addedAt', isGreaterThanOrEqualTo: start)
          .where('addedAt', isLessThanOrEqualTo: end)
          .get();

      double totalSold = 0;
      double totalExpenses = 0;
      // double totalProfit = 0;
      double dueAmounts = 0;
      double rawPurchases = 0;
      int dueCustomerCount = 0;

      final List<TransactionEntry> transactions = [];
      final List<ExpenseModel> expenses = [];

      // Process orders
      for (var doc in ordersSnap.docs) {
        final data = doc.data();
        final double amount = (data['totalAmount'] ?? 0).toDouble();
        final DateTime date =
            (data['orderTime'] as Timestamp?)?.toDate() ?? DateTime.now();

        totalSold += amount;

        transactions.add(
          TransactionEntry(
            id: doc.id,
            type: 'sold',
            description: data['customerName'] ?? 'Unknown',
            amount: amount,
            addedAt: date,
            itemType: data['itemType'] ?? 'Unknown',
          ),
        );
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

        transactions.add(
          TransactionEntry(
            id: exp.id,
            type: 'expense',
            description: exp.description,
            amount: exp.amount,
            addedAt: exp.addedAt,
          ),
        );
      }

      // ✅ Fetch dueAmounts and dueCustomerCount from CustomerRepository
      final customerRepo = ref.read(customerRepoProvider);
      final result = await customerRepo.calculateDueAmounts();
      dueAmounts = result.$1;
      dueCustomerCount = result.$2;

      // Compute final profit
      // totalProfit = totalSold - totalExpenses;

      // Sort transactions by newest first
      transactions.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      // Update state
      state = state.copyWith(
  isLoading: false,
  summary: BalanceSheetSummary(
    totalSold: totalSold,
    totalExpenses: totalExpenses,
    totalDue: dueAmounts,
    rawPurchases: rawPurchases,
    dueCustomerCount: dueCustomerCount,
  ),
  transactions: transactions,
  expenses: expenses,
);
   } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
