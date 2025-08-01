import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import 'transaction_entry_model.dart';
import 'balance_sheet_summary_model.dart';

class BalanceSheetState {
  final bool isLoading;
  final String? error;
  final BalanceSheetSummary? summary;
  final DateTimeRange? selectedRange;
  final List<TransactionEntry> transactions;
  final List<ExpenseModel> expenses;

  BalanceSheetState({
    this.isLoading = false,
    this.error,
    this.summary,
    this.selectedRange,
    this.expenses = const [],
    this.transactions = const [],
  });

  BalanceSheetState copyWith({
    bool? isLoading,
    String? error,
    BalanceSheetSummary? summary,
    DateTimeRange? selectedRange,
    List<ExpenseModel>? expenses,
    List<TransactionEntry>? transactions,
  }) {
    return BalanceSheetState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
      selectedRange: selectedRange ?? this.selectedRange,
      expenses: expenses ?? this.expenses,
      transactions: transactions ?? this.transactions,
    );
  }

  // Helper getters for backward compatibility
  double get totalSold => summary?.totalSold ?? 0.0;
  double get totalExpenses => summary?.totalExpenses ?? 0.0;
  double get totalProfit => summary?.netProfit ?? 0.0;
  double get dueAmounts => summary?.totalDue ?? 0.0;
  double get rawPurchases => summary?.rawPurchases ?? 0.0;
  int get dueCustomerCount => summary?.dueCustomerCount ?? 0;
}