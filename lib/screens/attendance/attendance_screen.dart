import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/async_value_widget.dart';
import '../../constants/app_constants.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  bool isDuringMorningShift() {
    final now = DateTime.now();
    return now.hour >= 9 && now.hour < 14;
  }

  bool isDuringAfternoonShift() {
    final now = DateTime.now();
    return now.hour >= 15 && now.hour < 18;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine current shift
    final String? shift = isDuringMorningShift()
        ? AppConstants.shiftMorning
        : isDuringAfternoonShift()
        ? AppConstants.shiftAfternoon
        : null;

    // If outside both shifts, show warning message
    if (shift == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Today\'s Attendance'),
        body: const Center(
          child: Text(
            'Attendance can only be viewed during:\n• 9:00–14:00 (Morning)\n• 15:00–18:00 (Afternoon)',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final attendanceAsync = ref.watch(todaysAttendanceStreamProvider(shift));
    final user = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      appBar: CustomAppBar(title: 'Today\'s Attendance ($shift shift)'),
      body: AsyncValueWidget(
        value: attendanceAsync,
        builder: (attendanceList) => ListView.builder(
          itemCount: attendanceList.length,
          itemBuilder: (context, index) {
            final att = attendanceList[index];
            return ListTile(
              title: Text('Worker ID: ${att.userId}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shift: ${att.shift}'),
                  Text('Status: ${att.status}'),
                  Text('Marked by: ${att.markedBy} at ${att.markedAt}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Add edit logic here
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMarkAttendanceDialog(context, ref, user?.uid ?? '', shift);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showMarkAttendanceDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String shift,
  ) {
    String status = 'present';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Shift: $shift'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: status,
              onChanged: (val) => status = val!,
              items: [
                'present',
                'absent',
                'halfDay',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final currentContext = context;
              final repo = ref.read(attendanceRepositoryProvider);
              await repo.markAttendance(
                userId: userId,
                shift: shift,
                status: status,
                markedBy: userId,
              );
              if (currentContext.mounted) {
                Navigator.of(currentContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
