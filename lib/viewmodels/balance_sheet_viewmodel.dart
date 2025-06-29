import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/balance_sheet_state.dart';

class BalanceSheetViewModel extends StateNotifier<BalanceSheetState> {
  BalanceSheetViewModel() : super(BalanceSheetState());

  Future<void> loadData({required DateTimeRange range}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final firestore = FirebaseFirestore.instance;
      final start = Timestamp.fromDate(range.start);
      final end = Timestamp.fromDate(range.end);

      // Example queries: you must adjust to your collections / structure
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

      final duesSnap = await firestore
          .collection('dues')
          .get(); // maybe not by date?

      // Sum up values
      double totalSold = 0;
      double totalExpenses = 0;
      double totalProfit = 0;
      double dueAmounts = 0;
      double rawPurchases = 0;

      for (var doc in ordersSnap.docs) {
        final data = doc.data();
        totalSold += (data['totalAmount'] ?? 0).toDouble();
      }

      for (var doc in expensesSnap.docs) {
        final data = doc.data();
        totalExpenses += (data['amount'] ?? 0).toDouble();
        if (data['type'] == 'rawMaterial') {
          rawPurchases += (data['amount'] ?? 0).toDouble();
        }
      }

      for (var doc in duesSnap.docs) {
        final data = doc.data();
        dueAmounts += (data['amount'] ?? 0).toDouble();
      }

      totalProfit = totalSold - totalExpenses;

      state = state.copyWith(
        isLoading: false,
        totalSold: totalSold,
        totalExpenses: totalExpenses,
        totalProfit: totalProfit,
        dueAmounts: dueAmounts,
        rawPurchases: rawPurchases,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
