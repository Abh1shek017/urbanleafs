import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:urbanleafs/constants/app_constants.dart';
import 'package:urbanleafs/models/payment_model.dart';
import 'package:urbanleafs/models/expense_model.dart';
import 'package:urbanleafs/providers/attendance_provider.dart';
import 'package:urbanleafs/providers/dashboard_stream_provider.dart';
import 'dashboard_state.dart';

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  final viewModel = DashboardViewModel(ref);

  // ⏱️ Real-time listeners
  ref.listen(todaysOrderCountStreamProvider, (_, __) {
    viewModel.loadOrderCount();
  });

  ref.listen(todayPaymentsStreamProvider, (_, __) {
    viewModel.loadTodayPayments();
  });

  ref.listen(todayExpensesStreamProvider, (_, __) {
    viewModel.loadTodayExpenses();
  });

  ref.listen(inventoryStatusStreamProvider, (_, __) {
    viewModel.loadInventoryStatus();
  });

  ref.listen(attendanceTriggerProvider, (_, __) {
    viewModel.loadAttendance();
  });

  return viewModel;
});

class DashboardViewModel extends StateNotifier<DashboardState> {
  final Ref ref;
  DashboardViewModel(this.ref) : super(DashboardState());

  /// Returns start and end timestamps for today's range
  (DateTime, DateTime) _getTodayRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    return (start, end);
  }

  Future<void> loadOrderCount() async {
    final (start, end) = _getTodayRange();

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    state = state.copyWith(totalOrders: snapshot.size);
  }

  Future<void> loadTodayPayments() async {
    final (start, end) = _getTodayRange();

    final snapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('receivedTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('receivedTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final payments = snapshot.docs.map((doc) => PaymentModel.fromSnapshot(doc)).toList();
    final total = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final customers = payments.map((p) => p.customerName).toSet().length;

    state = state.copyWith(
      todayEarnings: total,
      todayCustomerCount: customers,
    );
  }

  Future<void> loadTodayExpenses() async {
    final (start, end) = _getTodayRange();

    final snapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final expenses = snapshot.docs.map((doc) => ExpenseModel.fromSnapshot(doc)).toList();
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    state = state.copyWith(todayExpenses: total);
  }

  Future<void> loadInventoryStatus() async {
    final snapshot = await FirebaseFirestore.instance.collection('inventory').get();

    final total = snapshot.docs.fold<double>(
      0,
      (sum, doc) => sum + (doc.data()['stock'] ?? 0),
    );

    state = state.copyWith(totalInventory: total);
  }

  Future<void> loadAttendance() async {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);

    final repo = ref.read(attendanceRepositoryProvider);
    final records = await repo.getAllAttendanceForDay(dateOnly);

    int morningPresent = 0, morningAbsent = 0, afternoonPresent = 0, afternoonAbsent = 0;

    for (var record in records) {
      final present = record.status == AppConstants.statusPresent;
      final isMorning = record.shift == AppConstants.shiftMorning;

      if (isMorning) {
        present ? morningPresent++ : morningAbsent++;
      } else {
        present ? afternoonPresent++ : afternoonAbsent++;
      }
    }

    state = state.copyWith(
      morningPresent: morningPresent,
      morningAbsent: morningAbsent,
      afternoonPresent: afternoonPresent,
      afternoonAbsent: afternoonAbsent,
    );
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.wait([
        loadOrderCount(),
        loadTodayPayments(),
        loadTodayExpenses(),
        loadInventoryStatus(),
        loadAttendance(),
      ]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
