import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/balance_sheet_state.dart';
import '../models/expense_model.dart';

class BalanceSheetViewModel extends StateNotifier<BalanceSheetState> {
  BalanceSheetViewModel()
    : super(BalanceSheetState(dueCustomerCount: 0)); // ✅ FIXED

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

      double totalPrice = 0;
      double totalExpenses = 0;
      double totalProfit = 0;
      double dueAmounts = 0;
      double rawPurchases = 0;
      int dueCustomerCount = 0; // ✅ NEW

      for (var doc in ordersSnap.docs) {
        final data = doc.data();
        totalPrice += (data['totalPrice'] ?? 0).toDouble();
      }

      final List<ExpenseModel> expenses = [];
      for (var doc in expensesSnap.docs) {
        final exp = ExpenseModel.fromSnapshot(doc);
        expenses.add(exp);

        final normalizedType = exp.type.trim().toLowerCase();

        if (normalizedType == 'raw material') {
          rawPurchases += exp.amount;
        } else {
          totalExpenses += exp.amount;
        }
      }

      for (var doc in duesSnap.docs) {
        final data = doc.data();
        double amount = (data['amount'] ?? 0).toDouble();
        if (amount > 0) {
          dueAmounts += amount;
          dueCustomerCount++; // ✅ Count customers with due > 0
        }
      }

      totalProfit = totalPrice - totalExpenses;

      state = state.copyWith(
        isLoading: false,
        totalPrice: totalPrice,
        totalExpenses: totalExpenses,
        totalProfit: totalProfit,
        dueAmounts: dueAmounts,
        rawPurchases: rawPurchases,
        dueCustomerCount: dueCustomerCount, // ✅ FIXED
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
