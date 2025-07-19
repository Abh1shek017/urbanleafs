import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart' as table_calendar;
import '../../models/workers_summary_model.dart';
import '../../providers/attendance_summary_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
    ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceSummaryStateProvider);
    final workerList = state.workers;
    final totalWorkers = workerList.length;
    final totalPresent = workerList.fold<int>(0, (sum, w) => sum + w.presentDays);
    final totalAbsent = workerList.fold<int>(0, (sum, w) => sum + w.absentDays);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : Column(
    children: [
      // ✅ FilterBar remains fixed
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: _FilterBar(
          selectedMonth: selectedMonth,
          selectedYear: selectedYear,
          onFilterChanged: (month, year) {
            setState(() {
              selectedMonth = month;
              selectedYear = year;
            });
            ref.read(attendanceSummaryStateProvider.notifier).setFilter(month, year);
          },
        ),
      ),

      // ✅ This scrolls: SummaryCard + Worker List
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SummaryCard(
                totalWorkers: totalWorkers,
                morningPresent: totalPresent,
                morningAbsent: totalAbsent,
                afternoonPresent: totalPresent,
                afternoonAbsent: totalAbsent,
              ),
            ),
            const SizedBox(height: 8),
            ...workerList.map((worker) {
              return WorkerCard(
                worker: worker,
                onTap: () => _showWorkerDetailSheet(context, worker),
              );
            }).toList(),
          ],
        ),
      ),
    ],
  ),

    );
  }

  void _showWorkerDetailSheet(BuildContext context, WorkerSummaryModel worker) {
    final events = <DateTime, List<String>>{};
    for (final record in worker.attendanceHistory) {
      final day = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      events.putIfAbsent(day, () => []).add(record.status);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child:worker.worker.imageUrl.isNotEmpty
  ? CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: NetworkImage(worker.worker.imageUrl),
      onBackgroundImageError: (_, __) {},
    )
  : CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey.shade200,
      child: const Icon(Icons.person_outline, size: 40, color: Colors.grey),
    ),



                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      worker.worker.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "📞 ${worker.worker.phone}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "🏠 ${worker.worker.address}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalendar(events, context),
                  const SizedBox(height: 16),
                  const Text(
                    "Attendance History",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: worker.attendanceHistory.length,
                    itemBuilder: (context, index) {
                      final record = worker.attendanceHistory[index];
                      return ListTile(
                        title: Text(
                          "${record.date.toLocal().toIso8601String().split('T')[0]} - ${record.shift}",
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(record.status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            record.status,
                            style: TextStyle(
                              color: _statusColor(record.status),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDayAttendanceDialog(
    BuildContext context,
    DateTime day,
    List<String> statuses,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "${day.day}-${day.month}-${day.year} Attendance",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: statuses.isEmpty
            ? const Text("No attendance records for this day.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: statuses.map((status) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: _statusColor(status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(color: _statusColor(status)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    Map<DateTime, List<String>> events,
    BuildContext context,
  ) {
    return table_calendar.TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: DateTime.now(),
      calendarBuilders: table_calendar.CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final key = DateTime(day.year, day.month, day.day);
          if (events.containsKey(key)) {
            final status = events[key]!.first;
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(status),
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(color: _statusColor(status)),
                ),
              ),
            );
          }
          return null;
        },
      ),
      calendarStyle: const table_calendar.CalendarStyle(
        outsideDaysVisible: false,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        final key = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        );
        if (events.containsKey(key)) {
          _showDayAttendanceDialog(context, key, events[key]!);
        } else {
          _showDayAttendanceDialog(context, key, []);
        }
      },
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'halfDay':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class WorkerCard extends StatelessWidget {
  final WorkerSummaryModel worker;
  final VoidCallback onTap;
  const WorkerCard({super.key, required this.worker, required this.onTap});

  Color getBorderColor() {
    if (worker.absentDays > 5) return Colors.red;
    if (worker.halfDays > 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: getBorderColor(), width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
           worker.worker.imageUrl.isNotEmpty
  ? CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: NetworkImage(worker.worker.imageUrl),
      onBackgroundImageError: (_, __) {},
    )
  : CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey.shade200,
      child: const Icon(Icons.person_outline, size: 40, color: Colors.grey),
    ),


            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.worker.name.isNotEmpty
                        ? worker.worker.name
                        : "No Name",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusIconText(
                        Icons.check_circle,
                        Colors.green,
                        "P: ${worker.presentDays}",
                      ),
                      const SizedBox(width: 8),
                      _statusIconText(
                        Icons.cancel,
                        Colors.red,
                        "A: ${worker.absentDays}",
                      ),
                      const SizedBox(width: 8),
                      _statusIconText(
                        Icons.timelapse,
                        Colors.orange,
                        "H: ${worker.halfDays}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIconText(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
class _FilterBar extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final void Function(int month, int year) onFilterChanged;

  const _FilterBar({
    required this.selectedMonth,
    required this.selectedYear,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final currentYear = DateTime.now().year;

    return Row(
      children: [
        Expanded(
          child: DropdownButton<int>(
            value: selectedMonth,
            isExpanded: true,
            items: List.generate(12, (index) {
              final month = index + 1;
              return DropdownMenuItem(
                value: month,
                child: Text(monthNames[index]),
              );
            }),
            onChanged: (value) {
              if (value != null && value != selectedMonth) {
                onFilterChanged(value, selectedYear);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<int>(
            value: selectedYear,
            isExpanded: true,
            items: List.generate(10, (index) {
              final year = currentYear - index;
              return DropdownMenuItem(
                value: year,
                child: Text('$year'),
              );
            }),
            onChanged: (value) {
              if (value != null && value != selectedYear) {
                onFilterChanged(selectedMonth, value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final int totalWorkers;
  final int morningPresent;
  final int morningAbsent;
  final int afternoonPresent;
  final int afternoonAbsent;

  const SummaryCard({
    super.key,
    required this.totalWorkers,
    required this.morningPresent,
    required this.morningAbsent,
    required this.afternoonPresent,
    required this.afternoonAbsent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // TOTAL BOX
    Container(
      width: 130,
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOTAL",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              "$totalWorkers",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
    const SizedBox(width: 12),

    // WRAP the shift cards in Expanded to stretch to remaining space
    Expanded(
      child: Column(
        children: [
          // Morning
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Morning",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$morningPresent P / $morningAbsent A",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Afternoon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFBBDEFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Afternoon",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$afternoonPresent P / $afternoonAbsent A",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
),
);
}
}