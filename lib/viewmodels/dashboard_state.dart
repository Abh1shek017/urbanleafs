class DashboardState {
  final bool isLoading;
  final String? error;

  // Attendance
  final int morningPresent;
  final int afternoonPresent;
  final int morningAbsent;
  final int afternoonAbsent;

  // Orders & Payments
  final int totalOrders;
  final double todayEarnings;
  final int todayCustomerCount;
  final double todayExpenses;

  // Inventory
  final double totalInventory;

  DashboardState({
    this.isLoading = false,
    this.error,
    this.morningPresent = 0,
    this.afternoonPresent = 0,
    this.morningAbsent = 0,
    this.afternoonAbsent = 0,
    this.totalOrders = 0,
    this.todayEarnings = 0.0,
    this.todayCustomerCount = 0,
    this.todayExpenses = 0.0,
    this.totalInventory = 0.0,
  });

  factory DashboardState.initial() => DashboardState();

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    int? morningPresent,
    int? afternoonPresent,
    int? morningAbsent,
    int? afternoonAbsent,
    int? totalOrders,
    double? todayEarnings,
    int? todayCustomerCount,
    double? todayExpenses,
    double? totalInventory,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      morningPresent: morningPresent ?? this.morningPresent,
      afternoonPresent: afternoonPresent ?? this.afternoonPresent,
      morningAbsent: morningAbsent ?? this.morningAbsent,
      afternoonAbsent: afternoonAbsent ?? this.afternoonAbsent,
      totalOrders: totalOrders ?? this.totalOrders,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayCustomerCount: todayCustomerCount ?? this.todayCustomerCount,
      todayExpenses: todayExpenses ?? this.todayExpenses,
      totalInventory: totalInventory ?? this.totalInventory,
    );
  }
}
