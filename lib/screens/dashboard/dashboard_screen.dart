import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/footer_navigation.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/date_time_widget.dart';
import '../../utils/format_utils.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../providers/inventory_provider.dart';
// import '../../providers/attendance_provider.dart';          
import '../../providers/payment_provider.dart';
import '../../providers/expense_provider.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/daily_attendance_screen.dart';
import '../balance_sheet/balance_sheet_screen.dart';
import '../inventory/inventory_screen.dart';
import '../profile/profile_screen.dart';
import '../orders/today_orders_screen.dart';
import '../payments/today_payments_screen.dart';
import '../expense/today_expense_screen.dart';
import '../../providers/user_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 2; // Home tab

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardViewModelProvider.notifier).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final dashboardNotifier = ref.read(dashboardViewModelProvider.notifier);
    final userAsync = ref.watch(currentUserStreamProvider);

    String? profileImageUrl;
    userAsync.whenData((user) {
      profileImageUrl = user?.profileImageUrl;
    });

    final pages = [
      AttendanceScreen(),
      BalanceSheetScreen(),
      _buildHomeContent(context, dashboardState, dashboardNotifier),
      InventoryScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        fabSize: 80,
        profileImageUrl: profileImageUrl,
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    dashboardState,
    dashboardNotifier,
  ) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final todaysOrderCount = ref.watch(todaysOrderCountStreamProvider);
    final todaysEarnings = ref.watch(todaysPaymentsStreamProvider);
    final todaysExpenses = ref.watch(todaysExpensesStreamProvider);


    return Scaffold(
      appBar: const CustomAppBar(title: "UrbanLeafs"),
      body: RefreshIndicator(
        onRefresh: () async {
          await dashboardNotifier.loadDashboardData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateTimeWidget(
                onDayChange: (newDate) {
                  dashboardNotifier.loadDashboardData(newDate);
                },
              ),
              const SizedBox(height: 20),
              if (dashboardState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (dashboardState.error != null)
                Center(
                  child: Text(
                    "Error: ${dashboardState.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else ...[
                _buildQuickAccessCard(
                  context,
                  Icons.people,
                  "Today's Attendance",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DailyAttendanceScreen(),
                    ),
                  ),
                  subtitle:
                      "Morning: ${dashboardState.morningPresent} P / ${dashboardState.morningAbsent} A\n"
                      "Afternoon: ${dashboardState.afternoonPresent} P / ${dashboardState.afternoonAbsent} A",
                ),
                _buildQuickAccessCard(
                  context,
                  Icons.inventory_2,
                  "Today's Orders",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TodayOrdersScreen(),
                    ),
                  ),
                  subtitle: todaysOrderCount.when(
                    data: (count) => "$count orders",
                    loading: () => "Loading...",
                    error: (_, __) => "Error",
                  ),
                ),
                _buildQuickAccessCard(
                  context,
                  Icons.attach_money,
                  "Today's Payments",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TodayPaymentsScreen(),
                    ),
                  ),
                  subtitle: todaysEarnings.when(
                    data: (earningData) {
                      final total = earningData.fold<double>(
                        0,
                        (sum, p) => sum + (p.amount),
                      );
                      final customerCount = earningData
                          .map((p) => p.customerName)
                          .toSet()
                          .length;
                      return "${FormatUtils.formatCurrency(total)}\nFrom $customerCount customers";
                    },
                    loading: () => "Loading...",
                    error: (_, __) => "Error",
                  ),
                ),
                inventoryAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (inventoryItems) {
                    String subtitle;
                    if (inventoryItems.isEmpty) {
                      subtitle = "No items";
                    } else {
                      final first = inventoryItems[0];
                      final second = inventoryItems.length > 1
                          ? inventoryItems[1]
                          : null;
                      subtitle = second != null
                          ? "${first.itemName}: ${first.quantity} ${first.unit}  |  ${second.itemName}: ${second.quantity} ${second.unit}"
                          : "${first.itemName}: ${first.quantity} ${first.unit}";
                    }
                    return _buildQuickAccessCard(
                      context,
                      Icons.bar_chart,
                      "Inventory Status",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InventoryScreen(),
                        ),
                      ),
                      subtitle: subtitle,
                    );
                  },
                ),
                _buildQuickAccessCard(
                  context,
                  Icons.money_off_csred,
                  "Today's Expense",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TodayExpenseScreen(),
                    ),
                  ),
                  subtitle: todaysExpenses.when(
                    data: (expenseList) {
                      final total = expenseList.fold<double>(
                        0,
                        (sum, e) => sum + e.amount,
                      );
                      return FormatUtils.formatCurrency(total);
                    },
                    loading: () => "Loading...",
                    error: (_, __) => "Error",
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: subtitle != null ? 100 : 80,
            width: double.infinity,
            child: Row(
              children: [
                Icon(icon, size: 40, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) const SizedBox(height: 6),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}