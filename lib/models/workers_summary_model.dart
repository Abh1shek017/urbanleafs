import 'package:urbanleafs/models/worker_model.dart';
import 'package:urbanleafs/models/attendance_model.dart';

class WorkerSummaryModel {
  final WorkerModel worker;  // 🔥 keep your original static model here
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final List<AttendanceModel> attendanceHistory;

  WorkerSummaryModel({
    required this.worker,
    this.presentDays = 0,
    this.absentDays = 0,
    this.halfDays = 0,
    this.attendanceHistory = const [],
  });

  int get totalDays => presentDays + absentDays + halfDays;

  double get attendancePercentage {
    if (totalDays == 0) return 0;
    return (presentDays + 0.5 * halfDays) / totalDays;
  }

  String get overallStatus {
    if (absentDays > 5) return 'poor';
    if (halfDays > 3) return 'average';
    return 'good';
  }
}
