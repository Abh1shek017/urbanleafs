import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final DateTime date;
  final String shift; // "morning" or "afternoon"
  final String status; // "present", "absent", "halfDay"
  final DateTime markedAt;
  final String markedBy;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.shift,
    required this.status,
    required this.markedAt,
    required this.markedBy,
  });

  /// ✅ Create from raw map (e.g. Firestore .data())
  factory AttendanceModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return AttendanceModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shift: map['shift'] as String? ?? '',
      status: map['status'] as String? ?? '',
      markedAt: (map['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      markedBy: map['markedBy'] as String? ?? '',
    );
  }

  /// ✅ Create from Firestore DocumentSnapshot
  factory AttendanceModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceModel.fromMap(data, id: doc.id);
  }

  /// ✅ Convert to Firestore-friendly map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'shift': shift,
      'status': status,
      'markedAt': Timestamp.fromDate(markedAt),
      'markedBy': markedBy,
    };
  }
}
