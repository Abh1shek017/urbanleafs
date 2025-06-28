import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:urbanleafs/constants/app_constants.dart';
import 'package:urbanleafs/models/payment_model.dart';
import 'package:urbanleafs/providers/attendance_provider.dart';
import 'package:urbanleafs/models/expense_model.dart';
import 'dashboard_state.dart';

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
      return DashboardViewModel(ref);
    });

class DashboardViewModel extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardViewModel(this.ref) : super(DashboardState());

  Future<void> loadDashboardData([DateTime? selectedDate]) async {
    final date = selectedDate ?? DateTime.now();
    state = state.copyWith(isLoading: true);

    try {
      /// -------------------
      /// 1. Load Attendance
      /// -------------------
      final repo = ref.read(attendanceRepositoryProvider);
      final records = await repo.getAllAttendanceForDay(date);

      int morningPresent = 0;
      int morningAbsent = 0;
      int afternoonPresent = 0;
      int afternoonAbsent = 0;

      for (var record in records) {
        if (record.shift == AppConstants.shiftMorning) {
          if (record.status == AppConstants.statusPresent) {
            morningPresent++;
          } else if (record.status == AppConstants.statusAbsent) {
            morningAbsent++;
          }
        } else if (record.shift == AppConstants.shiftAfternoon) {
          if (record.status == AppConstants.statusPresent) {
            afternoonPresent++;
          } else if (record.status == AppConstants.statusAbsent) {
            afternoonAbsent++;
          }
        }
      }

      /// -------------------
      /// 2. Load Payments
      /// -------------------
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));

      final paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where(
            'receivedTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'receivedTime',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get();

      final payments = paymentSnapshot.docs
          .map((doc) => PaymentModel.fromSnapshot(doc))
          .toList();

      final todayEarnings = payments.fold<double>(
        0.0,
        (total, p) => total + p.amount,
      );
      final todayCustomerCount = payments
          .map((p) => p.customerName)
          .toSet()
          .length;

      /// -------------------
      /// 3. Load Expenses
      /// -------------------
      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final expenses = expenseSnapshot.docs
          .map((doc) => ExpenseModel.fromSnapshot(doc))
          .toList();

      final todayExpenses = expenses.fold<double>(
        0.0,
        (total, e) => total + e.amount,
      );

      /// -------------------
      /// 4. Set Final State
      /// -------------------
      state = state.copyWith(
        isLoading: false,
        error: null,
        morningPresent: morningPresent,
        afternoonPresent: afternoonPresent,
        morningAbsent: morningAbsent,
        afternoonAbsent: afternoonAbsent,
        todayEarnings: todayEarnings,
        todayCustomerCount: todayCustomerCount,
        todayExpenses: todayExpenses, // ✅ NEW FIELD
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
