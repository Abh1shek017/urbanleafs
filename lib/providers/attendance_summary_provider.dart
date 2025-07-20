import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workers_summary_model.dart';
import '../repositories/attendance_repository.dart'; // adjust path
import '../providers/attendance_provider.dart';

/// 🔁 Refresh trigger provider
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
      error: error ?? this.error,
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
    loadSummaries();
  }

  Future<void> loadSummaries() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await repo.getWorkerSummaries(
        month: state.month,
        year: state.year,
      );
      state = state.copyWith(workers: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setFilter(int month, int year) {
    state = state.copyWith(month: month, year: year);
    loadSummaries();
  }
}

final attendanceSummaryStateProvider =
    StateNotifierProvider<AttendanceSummaryNotifier, AttendanceSummaryState>((
  ref,
) {
  final repo = ref.read(attendanceRepositoryProvider);

  // 👇 Watch the refresh trigger so this provider rebuilds when it changes
  ref.watch(attendanceRefreshTriggerProvider);

  return AttendanceSummaryNotifier(repo);
});
