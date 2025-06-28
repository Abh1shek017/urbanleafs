import 'package:flutter/material.dart'; // For DateUtils
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/attendance_repository.dart';
// import '../constants/app_constants.dart';

/// ✅ Repository provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// ✅ AttendanceStatusParams to pass both userId and shift
class AttendanceStatusParams {
  final String userId;
  final String shift;

  AttendanceStatusParams({required this.userId, required this.shift});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStatusParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          shift == other.shift;

  @override
  int get hashCode => userId.hashCode ^ shift.hashCode;
}

/// ✅ Attendance Status Provider per user & shift
final attendanceStatusProvider =
    StateNotifierProvider.family<
      AttendanceStatusNotifier,
      String,
      AttendanceStatusParams
    >((ref, params) {
      final repo = ref.watch(attendanceRepositoryProvider);
      return AttendanceStatusNotifier(
        userId: params.userId,
        shift: params.shift,
        repo: repo,
      );
    });

/// 🧠 AttendanceStatusNotifier fetches status from Firestore
class AttendanceStatusNotifier extends StateNotifier<String> {
  final String userId;
  final String shift;
  final AttendanceRepository repo;

  AttendanceStatusNotifier({
    required this.userId,
    required this.shift,
    required this.repo,
  }) : super('') {
    _loadInitialStatus();
  }

  Future<void> _loadInitialStatus() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final snapshot = await repo.getAttendanceForUserOnDate(userId, today);
    final matching = snapshot.where((doc) => doc.shift == shift).firstOrNull;

    if (matching != null) {
      state = matching.status;
    } else {
      state = ''; // Not marked yet
    }
  }

  void updateStatus(String status) {
    state = status;
  }

  void clearStatus() {
    state = '';
  }
}
