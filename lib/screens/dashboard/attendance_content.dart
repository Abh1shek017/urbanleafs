import 'package:flutter/material.dart';

class AttendanceContent extends StatelessWidget {
  const AttendanceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Attendance",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildAttendanceCard(context, 'Rajesh Kumar', 'Present', '9:05 AM'),
          _buildAttendanceCard(context, 'Suresh Yadav', 'Absent', '-'),
          _buildAttendanceCard(context, 'Mukesh Patel', 'Half Day', '11:30 AM'),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, String name, String status, String time) {
    Color statusColor = status == 'Present'
        ? Colors.green.shade400
        : status == 'Absent'
            ? Colors.red.shade400
            : Colors.orange.shade400;

    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(name),
        subtitle: Text("Status: $status"),
        trailing: Chip(
          label: Text(time),
          // ignore: deprecated_member_use
          backgroundColor: statusColor.withOpacity(0.2),
        ),
      ),
    );
  }
}