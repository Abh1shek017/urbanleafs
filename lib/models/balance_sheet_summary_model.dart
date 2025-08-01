class BalanceSheetSummary {
  final double totalSold;
  final double totalExpenses;
  final double rawPurchases;
  final double totalDue;
  final int dueCustomerCount;

  const BalanceSheetSummary({
    this.totalSold = 0.0,
    this.totalExpenses = 0.0,
    this.rawPurchases = 0.0,
    this.totalDue = 0.0,
    this.dueCustomerCount = 0,
  });

  // Helper getters for calculations
  double get netProfit => totalSold - totalExpenses - rawPurchases;
  double get grossProfit => totalSold - rawPurchases;
}