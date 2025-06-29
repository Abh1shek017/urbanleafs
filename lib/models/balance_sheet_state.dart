class BalanceSheetState {
  final bool isLoading;
  final String? error;

  final double totalSold;
  final double totalExpenses;
  final double totalProfit;
  final double dueAmounts;
  final double rawPurchases;

  BalanceSheetState({
    this.isLoading = false,
    this.error,
    this.totalSold = 0,
    this.totalExpenses = 0,
    this.totalProfit = 0,
    this.dueAmounts = 0,
    this.rawPurchases = 0,
  });

  BalanceSheetState copyWith({
    bool? isLoading,
    String? error,
    double? totalSold,
    double? totalExpenses,
    double? totalProfit,
    double? dueAmounts,
    double? rawPurchases,
  }) {
    return BalanceSheetState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalSold: totalSold ?? this.totalSold,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalProfit: totalProfit ?? this.totalProfit,
      dueAmounts: dueAmounts ?? this.dueAmounts,
      rawPurchases: rawPurchases ?? this.rawPurchases,
    );
  }
}
