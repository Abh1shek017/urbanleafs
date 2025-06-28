import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'daily_attendance_shift_page.dart';
// import 'package:urbanleafs/utils/capitalize.dart';

class ShiftAttendanceScreen extends StatelessWidget {
  const ShiftAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Today's Attendance"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Morning Shift"),
              Tab(text: "Afternoon Shift"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DailyAttendanceShiftPage(shift: 'Morning'),
            DailyAttendanceShiftPage(shift: 'Afternoon'),
          ],
        ),
      ),
    );
  }
}
