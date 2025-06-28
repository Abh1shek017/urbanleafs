import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';

class AttendanceTile extends StatelessWidget {
  final AttendanceModel attendance;
  final VoidCallback? onEdit;

  const AttendanceTile({
    super.key,
    required this.attendance,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('Worker ID: ${attendance.userId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shift: ${attendance.shift.capitalize()}'),
            Text('Status: ${attendance.status.capitalize()}'),
            Text('Marked by: ${attendance.markedBy} at ${attendance.markedAt.hour}:${attendance.markedAt.minute}'),
          ],
        ),
        trailing: onEdit != null
            ? IconButton(
                icon: Icon(Icons.edit),
                onPressed: onEdit,
              )
            : null,
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1).replaceAll('_', ' ');
  }
}