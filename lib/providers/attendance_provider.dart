import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urbanleafs/constants/app_constants.dart';
import '../repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

/// Provider for the AttendanceRepository
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// Stream provider for today's attendance by shift
final todaysAttendanceStreamProvider = StreamProvider.family
    .autoDispose<List<AttendanceModel>, String>((ref, shift) {
      final repository = ref.watch(attendanceRepositoryProvider);
      return repository.getTodaysAttendance(DateTime.now(), shift: shift);
    });
final attendanceStatsProvider = FutureProvider.family
    .autoDispose<Map<String, int>, ({String shift, DateTime date})>((
      ref,
      params,
    ) async {
      final repo = ref.read(attendanceRepositoryProvider);
      return await repo.getTodayAttendanceStats(
        date: params.date,
        shift: params.shift,
      );
    });
final todayAttendanceProvider =
    FutureProvider<Map<String, Map<String, String>>>((ref) async {
      final repo = ref.watch(attendanceRepositoryProvider);
      final today = DateTime.now();

      final shifts = [AppConstants.shiftMorning, AppConstants.shiftAfternoon];
      final result = <String, Map<String, String>>{};

      for (var shift in shifts) {
        final records = await repo
            .getTodaysAttendance(today, shift: shift)
            .first;
        result[shift] = {for (var a in records) a.userId: a.status};
      }

      return result;
    });
