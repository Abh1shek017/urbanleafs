import '../models/expense_model.dart';
import '../models/transaction_entry.dart';

class BalanceSheetState {
  final bool isLoading;
  final String? error;

  final double totalSold;
  final double totalExpenses;
  final double totalProfit;
  final double dueAmounts;
  final double rawPurchases;
  final int dueCustomerCount;

  final List<TransactionEntry> transactions;
  final List<ExpenseModel> expenses;

  BalanceSheetState({
    this.isLoading = false,
    this.error,
    this.totalSold = 0,
    this.totalExpenses = 0,
    this.totalProfit = 0,
    this.dueAmounts = 0,
    this.rawPurchases = 0,
    this.dueCustomerCount = 0,
    this.expenses = const [],
    this.transactions = const [],
  });

  BalanceSheetState copyWith({
    bool? isLoading,
    String? error,
    double? totalSold,
    double? totalExpenses,
    double? totalProfit,
    double? dueAmounts,
    double? rawPurchases,
    int? dueCustomerCount,
    List<ExpenseModel>? expenses,
    List<TransactionEntry>? transactions,
  }) {
    return BalanceSheetState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalSold: totalSold ?? this.totalSold,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalProfit: totalProfit ?? this.totalProfit,
      dueAmounts: dueAmounts ?? this.dueAmounts,
      rawPurchases: rawPurchases ?? this.rawPurchases,
      dueCustomerCount: dueCustomerCount ?? this.dueCustomerCount,
      expenses: expenses ?? this.expenses,
      transactions: transactions ?? this.transactions,
    );
  }
}
