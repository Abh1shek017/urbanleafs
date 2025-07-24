import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/balance_sheet_state.dart';
import '../models/transaction_entry.dart';
import '../repositories/order_repository.dart';
import '../providers/order_provider.dart';
import 'package:flutter/material.dart'; // for DateTimeRange

final balanceSheetProvider =
    StateNotifierProvider<BalanceSheetNotifier, BalanceSheetState>(
      (ref) => BalanceSheetNotifier(
        ref.read(orderRepositoryProvider),
        FirebaseFirestore.instance,
      ),
    );

class BalanceSheetNotifier extends StateNotifier<BalanceSheetState> {
  final OrderRepository orderRepo;
  final FirebaseFirestore firestore;

  BalanceSheetNotifier(this.orderRepo, this.firestore)
    : super(BalanceSheetState()) {
    loadData(); // Load initial data
  }

  Future<void> loadData({DateTimeRange? range}) async {
    try {
      state = state.copyWith(isLoading: true);

      // 🔸 Load and filter orders
      Query orderQuery = firestore.collectionGroup('orders');
      if (range != null) {
        orderQuery = orderQuery
            .where('orderTime', isGreaterThanOrEqualTo: range.start)
            .where('orderTime', isLessThanOrEqualTo: range.end);
      }

      final orderSnap = await orderQuery.get();
      final orderModels = orderSnap.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      double totalSold = 0.0;
      double dueAmounts = 0.0;
      int dueCustomerCount = 0;

      final soldTransactions = orderModels.map((order) {
        totalSold += order.totalAmount;
        // if (order.dueAmount > 0) {
        //   dueAmounts += order.dueAmount;
        //   dueCustomerCount++;
        // }
        return TransactionEntry(
          id: order.id,
          type: 'sold',
          description: order.customerName,
          amount: order.totalAmount,
          addedAt: order.orderTime,
          itemType: order.itemType,
        );
      }).toList();

      // 🔸 Load and filter expenses
      Query expenseQuery = firestore.collection('expenses');
      if (range != null) {
        expenseQuery = expenseQuery
            .where('addedAt', isGreaterThanOrEqualTo: range.start)
            .where('addedAt', isLessThanOrEqualTo: range.end);
      }

      final expenseSnap = await expenseQuery.get();

      double totalExpenses = 0.0;
      double rawPurchases = 0.0;

      final expenseTransactions = <TransactionEntry>[];
      final rawTransactions = <TransactionEntry>[];

      for (final doc in expenseSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final amt = (data['amount'] ?? 0).toDouble();
        final type = data['type']?.toString().toLowerCase() ?? 'general';
        final addedAt =
            (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final description = data['description']?.toString() ?? 'No Description';

        final entry = TransactionEntry(
          id: doc.id,
          type: type == 'raw' ? 'raw_purchase' : 'expense',
          description: description,
          amount: amt,
          addedAt: addedAt,
        );

        if (type == 'raw material') {
          rawPurchases += amt;
          rawTransactions.add(entry);
        } else {
          totalExpenses += amt;
          expenseTransactions.add(entry);
        }
      }

      // 🔸 Combine and sort all transactions
      final allTransactions = [
        ...soldTransactions,
        ...expenseTransactions,
        ...rawTransactions,
      ]..sort((a, b) => b.addedAt.compareTo(a.addedAt)); // latest first

      // 🔸 Update state
      state = state.copyWith(
        isLoading: false,
        error: null,
        transactions: allTransactions,
        totalSold: totalSold,
        totalExpenses: totalExpenses,
        rawPurchases: rawPurchases,
        dueAmounts: dueAmounts,
        dueCustomerCount: dueCustomerCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
