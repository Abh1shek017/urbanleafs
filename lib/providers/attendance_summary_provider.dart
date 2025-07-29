import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workers_summary_model.dart';
import '../repositories/attendance_repository.dart';
import '../providers/attendance_provider.dart';

/// 🔁 Manual refresh trigger
final attendanceRefreshTriggerProvider = StateProvider<int>((ref) => 0);

class AttendanceSummaryState {
  final int month;
  final int year;
  final List<WorkerSummaryModel> workers;
  final bool isLoading;
  final String? error;

  AttendanceSummaryState({
    required this.month,
    required this.year,
    required this.workers,
    this.isLoading = false,
    this.error,
  });

  AttendanceSummaryState copyWith({
    int? month,
    int? year,
    List<WorkerSummaryModel>? workers,
    bool? isLoading,
    String? error,
  }) {
    return AttendanceSummaryState(
      month: month ?? this.month,
      year: year ?? this.year,
      workers: workers ?? this.workers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AttendanceSummaryNotifier extends StateNotifier<AttendanceSummaryState> {
  final AttendanceRepository repo;

  AttendanceSummaryNotifier(this.repo)
    : super(
        AttendanceSummaryState(
          month: DateTime.now().month,
          year: DateTime.now().year,
          workers: [],
          isLoading: true,
        ),
      ) {
    loadSummaries(); // ✅ Safe place to call on construction
  }
  Future<void> loadSummaries() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await repo.getWorkerSummaries(
        month: state.month,
        year: state.year,
      );
      state = state.copyWith(workers: data, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setFilter(int month, int year) {
    state = state.copyWith(month: month, year: year);
    loadSummaries();
  }
}

/// ✅ Updated provider: also watches refresh trigger
final attendanceSummaryStateProvider =
    StateNotifierProvider<AttendanceSummaryNotifier, AttendanceSummaryState>((
      ref,
    ) {
      final repo = ref.read(attendanceRepositoryProvider);

      // 👇 This will trigger the provider to rebuild when the refresh counter changes
      ref.watch(attendanceRefreshTriggerProvider);

      final notifier = AttendanceSummaryNotifier(repo);
      notifier.loadSummaries(); // 👈 Force reloading when refreshed or rebuilt
      return notifier;
    });
