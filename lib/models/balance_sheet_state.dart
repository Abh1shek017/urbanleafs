import '../models/expense_model.dart'; // adjust path as needed

class BalanceSheetState {
  final bool isLoading;
  final String? error;

  final double totalPrice;
  final double totalExpenses;
  final double totalProfit;
  final double dueAmounts;
  final double rawPurchases;
  final int dueCustomerCount;

  final List<ExpenseModel> expenses; // ✅ Add this line

  BalanceSheetState({
    this.isLoading = false,
    this.error,
    this.totalPrice = 0,
    this.totalExpenses = 0,
    this.totalProfit = 0,
    this.dueAmounts = 0,
    this.rawPurchases = 0,
    this.dueCustomerCount = 0,
    this.expenses = const [], // ✅ Default empty list
  });

  BalanceSheetState copyWith({
    bool? isLoading,
    String? error,
    double? totalPrice,
    double? totalExpenses,
    double? totalProfit,
    double? dueAmounts,
    double? rawPurchases,
    int? dueCustomerCount,
    List<ExpenseModel>? expenses, // ✅ Add this
  }) {
    return BalanceSheetState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalPrice: totalPrice ?? this.totalPrice,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalProfit: totalProfit ?? this.totalProfit,
      dueAmounts: dueAmounts ?? this.dueAmounts,
      rawPurchases: rawPurchases ?? this.rawPurchases,
      dueCustomerCount: dueCustomerCount ?? this.dueCustomerCount,
      expenses: expenses ?? this.expenses, // ✅ Copy this
    );
  }
}
