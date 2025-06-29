import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ======================
// BalanceSheetState Model
// ======================
class BalanceSheetState {
  final bool isLoading;
  final String? error;

  final double totalSold;
  final double totalExpenses;
  final double totalProfit;
  final double dueAmounts;
  final double rawPurchases;

  final List<ExpenseModel> expenses; // for transaction list

  BalanceSheetState({
    this.isLoading = false,
    this.error,
    this.totalSold = 0,
    this.totalExpenses = 0,
    this.totalProfit = 0,
    this.dueAmounts = 0,
    this.rawPurchases = 0,
    this.expenses = const [],
  });

  BalanceSheetState copyWith({
    bool? isLoading,
    String? error,
    double? totalSold,
    double? totalExpenses,
    double? totalProfit,
    double? dueAmounts,
    double? rawPurchases,
    List<ExpenseModel>? expenses,
  }) {
    return BalanceSheetState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalSold: totalSold ?? this.totalSold,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalProfit: totalProfit ?? this.totalProfit,
      dueAmounts: dueAmounts ?? this.dueAmounts,
      rawPurchases: rawPurchases ?? this.rawPurchases,
      expenses: expenses ?? this.expenses,
    );
  }
}

// ======================
// Expense Model
// ======================
class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final String type;
  final DateTime addedAt;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.addedAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? '',
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }
}

// ======================
// ViewModel
// ======================
class BalanceSheetViewModel extends StateNotifier<BalanceSheetState> {
  BalanceSheetViewModel() : super(BalanceSheetState());

  Future<void> loadData({required DateTimeRange range}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final firestore = FirebaseFirestore.instance;
      final start = Timestamp.fromDate(range.start);
      final end = Timestamp.fromDate(range.end);

      // ========== ORDERS ==========
      final ordersSnap = await firestore
          .collection('orders')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .get();

      double totalSold = 0;
      for (var doc in ordersSnap.docs) {
        final data = doc.data();
        totalSold += (data['totalAmount'] ?? 0).toDouble();
      }

      // ========== EXPENSES ==========
      final expensesSnap = await firestore
          .collection('expenses')
          .where('addedAt', isGreaterThanOrEqualTo: start)
          .where('addedAt', isLessThanOrEqualTo: end)
          .get();

      double totalExpenses = 0;
      double rawPurchases = 0;
      List<ExpenseModel> expenses = [];

      for (var doc in expensesSnap.docs) {
        final exp = ExpenseModel.fromFirestore(doc);
        expenses.add(exp);
        totalExpenses += exp.amount;
        if (exp.type == 'rawMaterial') {
          rawPurchases += exp.amount;
        }
      }

      // ========== DUES ==========
      final duesSnap = await firestore.collection('dues').get();
      double dueAmounts = 0;
      for (var doc in duesSnap.docs) {
        final data = doc.data();
        dueAmounts += (data['amount'] ?? 0).toDouble();
      }

      // ========== PROFIT ==========
      double totalProfit = totalSold - totalExpenses;

      // ========== UPDATE STATE ==========
      state = state.copyWith(
        isLoading: false,
        totalSold: totalSold,
        totalExpenses: totalExpenses,
        totalProfit: totalProfit,
        dueAmounts: dueAmounts,
        rawPurchases: rawPurchases,
        expenses: expenses,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ======================
// Provider
// ======================
final balanceSheetViewModelProvider =
    StateNotifierProvider<BalanceSheetViewModel, BalanceSheetState>((ref) {
      return BalanceSheetViewModel();
    });
