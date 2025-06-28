import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

// Repository Provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

// Stream of all attendance records
final allAttendanceStreamProvider = StreamProvider.autoDispose<List<AttendanceModel>>(
  (ref) {
    final repository = ref.watch(attendanceRepositoryProvider);
    return repository.getAllAttendance();
  },
);

// Stream of today's attendance only
final todaysAttendanceStreamProvider = StreamProvider.autoDispose<List<AttendanceModel>>(
  (ref) {
    final repository = ref.watch(attendanceRepositoryProvider);
    return repository.getTodaysAttendance(DateTime.now(), shift: 'morning');
  },
);

// Future to mark attendance
final markAttendanceFutureProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, attendanceData) async {
    final repository = ref.watch(attendanceRepositoryProvider);

    // Extract parameters from the map safely
    final userId = attendanceData['userId'] as String;
    final shift = attendanceData['shift'] as String;
    final status = attendanceData['status'] as String;
    final markedBy = attendanceData['markedBy'] as String;

    await repository.markAttendance(
      userId: userId,
      shift: shift,
      status: status,
      markedBy: markedBy,
    );
  },
);
