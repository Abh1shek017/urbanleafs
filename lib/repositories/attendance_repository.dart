import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For DateUtils
import 'package:urbanleafs/constants/app_constants.dart';
import '../models/attendance_model.dart';
import './base_repository.dart';

class AttendanceRepository extends BaseRepository {
  AttendanceRepository()
    : super(FirebaseFirestore.instance.collection('attendance'));

  /// 🔁 Stream: All attendance records
  Stream<List<AttendanceModel>> getAllAttendance() {
    return collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AttendanceModel.fromSnapshot(doc))
          .toList(),
    );
  }

  /// 🔁 Stream: Today's attendance for a specific shift
  Stream<List<AttendanceModel>> getTodaysAttendance(
    DateTime date, {
    required String shift,
  }) {
    final today = DateUtils.dateOnly(date);
    return collection
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .where('shift', isEqualTo: shift)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromSnapshot(doc))
              .toList(),
        );
  }

  /// 🔁 Stream: Count of today's attendance for a specific shift and Present only
  Stream<int> countTodaysAttendance(DateTime date, {required String shift}) {
    final today = DateUtils.dateOnly(date);
    return collection
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .where('shift', isEqualTo: shift)
        .where('status', isEqualTo: 'present')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// ✅ Mark attendance idempotently (no duplicate for same user/date/shift)
  Future<void> markAttendance({
    required String userId,
    required String shift,
    required String status,
    required String markedBy,
  }) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final query = await collection
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .where('shift', isEqualTo: shift)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      await collection.add({
        'userId': userId,
        'date': Timestamp.fromDate(today),
        'shift': shift,
        'status': status,
        'markedAt': Timestamp.now(),
        'markedBy': markedBy,
      });
    } else {
      await query.docs.first.reference.update({
        'status': status,
        'markedAt': Timestamp.now(),
        'markedBy': markedBy,
      });
    }
  }

  Future<List<AttendanceModel>> getAllAttendanceForDay(DateTime date) async {
    final morning = await getTodaysAttendance(
      date,
      shift: AppConstants.shiftMorning,
    ).first;
    final afternoon = await getTodaysAttendance(
      date,
      shift: AppConstants.shiftAfternoon,
    ).first;
    return [...morning, ...afternoon];
  }

  /// 📄 One-time fetch: Get a user's attendance for a specific date
  Future<List<AttendanceModel>> getAttendanceForUserOnDate(
    String userId,
    DateTime date,
  ) async {
    final today = Timestamp.fromDate(DateUtils.dateOnly(date));
    final snapshot = await collection
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceModel.fromSnapshot(doc))
        .toList();
  }

  Future<Map<String, int>> getTodayAttendanceStats({
    required DateTime date,
    required String shift,
  }) async {
    final today = DateUtils.dateOnly(date);

    final snapshot = await collection
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .where('shift', isEqualTo: shift)
        .get();

    int presentCount = 0;
    int absentCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = (data as Map<String, dynamic>)['status'] as String? ?? '';
      if (status == AppConstants.statusPresent) {
        presentCount++;
      } else if (status == AppConstants.statusAbsent) {
        absentCount++;
      }
    }

    return {'present': presentCount, 'absent': absentCount};
  }
}
