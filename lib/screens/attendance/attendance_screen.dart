import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workers_summary_model.dart';
import '../../providers/attendance_summary_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/attendance_model.dart';
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final notifier = ref.read(attendanceSummaryStateProvider.notifier);
    final now = DateTime.now();

    // Reset the selected month/year to current
    notifier.setFilter(now.month, now.year);

    // Reload data for current month/year
    notifier.loadSummaries();
  });
}

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceSummaryStateProvider);
    final workerList = state.workers;
    final totalWorkers = workerList.length;
    final totalPresent = workerList.fold<int>(
      0,
      (sum, w) => sum + w.presentDays,
    );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: _FilterBar(
                    selectedMonth: selectedMonth,
                    selectedYear: selectedYear,
                    onFilterChanged: (month, year) {
                      setState(() {
                        selectedMonth = month;
                        selectedYear = year;
                      });
                      ref
                          .read(attendanceSummaryStateProvider.notifier)
                          .setFilter(month, year);
                    },
                  ),
                ),

                // ✅ This scrolls: SummaryCard + Worker List
               Expanded(
  child: RefreshIndicator(
    onRefresh: () async {
      final notifier = ref.read(attendanceSummaryStateProvider.notifier);
      await notifier.loadSummaries(); // ✅ Await data reload
    },
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
            onTap: () => _showWorkerDetailSheet(
              context,
              worker,
              selectedMonth,
              selectedYear,
            ),
          );
        }).toList(),
      ],
    ),
  ),
),


              ],
            ),
    );
  }
void _showWorkerDetailSheet(
  BuildContext context,
  WorkerSummaryModel worker,
  int selectedMonth,
  int selectedYear,
) {
  final now = DateTime.now();

  final events = <DateTime, List<String>>{};
  final Map<DateTime, List<String>> shiftMap = {};

  // Compute statuses (including half-day logic)
  for (final record in worker.attendanceHistory) {
    final date = DateTime(record.date.year, record.date.month, record.date.day);
    shiftMap.putIfAbsent(date, () => []).add(record.shift);
  }

  for (final entry in shiftMap.entries) {
    final date = entry.key;
    final shifts = entry.value;

    final dayRecords = worker.attendanceHistory.where((rec) =>
      rec.date.year == date.year &&
      rec.date.month == date.month &&
      rec.date.day == date.day).toList();

    if (shifts.length == 1 && dayRecords.any((r) => r.status.toLowerCase() == 'present')) {
      events[date] = ['half-day'];
    } else if (dayRecords.every((r) => r.status.toLowerCase() == 'absent')) {
      events[date] = ['absent'];
    } else if (dayRecords.every((r) => r.status.toLowerCase() == 'present')) {
      events[date] = ['present'];
    } else {
      // Mixed present and absent — treat as half-day for simplicity
      events[date] = ['half-day'];
    }
  }

  DateTime displayedMonth = DateTime(selectedYear, selectedMonth);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: worker.worker.imageUrl.isNotEmpty
                          ? CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.green,
                              backgroundImage: NetworkImage(worker.worker.imageUrl),
                              onBackgroundImageError: (_, __) {},
                            )
                          : const CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.green,
                              child: Icon(Icons.person, size: 40, color: Colors.white),
                            ),
                    ),

                    const SizedBox(height: 8),

                    // Name
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

                    // Phone + Address in same row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final Uri phoneUri = Uri(scheme: 'tel', path: worker.worker.phone);
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch phone dialer')),
                              );
                            }
                          },
                          child: Text(
                            "📞 ${worker.worker.phone}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blueAccent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "🏠 ${worker.worker.address}",
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Month Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed: () {
                            setState(() {
                              displayedMonth = DateTime(
                                displayedMonth.year,
                                displayedMonth.month - 1,
                              );
                            });
                          },
                        ),
                        Text(
                          "${_monthName(displayedMonth.month)} ${displayedMonth.year}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () {
                            final nextMonth = DateTime(
                              displayedMonth.year,
                              displayedMonth.month + 1,
                            );
                            if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                              setState(() {
                                displayedMonth = nextMonth;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Calendar
                    TableCalendar(
                      focusedDay: displayedMonth,
                      firstDay: DateTime(2020),
                      lastDay: DateTime(now.year, now.month, 31),
                      calendarFormat: CalendarFormat.month,
                      availableGestures: AvailableGestures.none,
                      headerVisible: false,
                      daysOfWeekVisible: true,
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      calendarStyle: const CalendarStyle(
                        isTodayHighlighted: true,
                        outsideDaysVisible: false,
                        defaultTextStyle: TextStyle(color: Colors.black),
                        weekendTextStyle: TextStyle(color: Colors.black),
                        markersMaxCount: 1,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, _) {
                          final isInMonth = day.month == displayedMonth.month;
                          final statusList = events[DateTime(day.year, day.month, day.day)];
                          final isToday = day.year == now.year &&
                              day.month == now.month &&
                              day.day == now.day;

                          if (!isInMonth) return const SizedBox.shrink();

                          Color? outerColor;
                          if (statusList != null && statusList.isNotEmpty) {
                            final status = statusList.first;
                            if (status == 'present') {
                              outerColor = Colors.green;
                            } else if (status == 'absent') {
                              outerColor = Colors.red;
                            } else if (status == 'half-day') {
                              outerColor = Colors.orange;
                            }
                          }

                          return Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (outerColor != null)
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: outerColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (isToday)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: outerColor != null ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      "Attendance History",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Filter and sort attendance
                    Builder(
                      builder: (context) {
                        final filteredHistory = List<AttendanceModel>.from(
                          worker.attendanceHistory.where((att) =>
                            att.date.month == displayedMonth.month &&
                            att.date.year == displayedMonth.year),
                        );
                        filteredHistory.sort((a, b) => b.date.compareTo(a.date));

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final record = filteredHistory[index];
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
                                  color: _statusColor(record.status).withValues(alpha: 0.2),
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
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

  // --------------------------------------------
  // 📌 Helper functions (place at bottom of file)
  // --------------------------------------------

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'half-day':
      case 'halfday':
        return Colors.deepOrange; // saffron color
      default:
        return Colors.grey;
    }
  }

  String _monthName(int month) {
    const months = [
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
    return months[month - 1];
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
                    backgroundColor: const Color.fromARGB(255, 77, 196, 81),
                    backgroundImage: NetworkImage(worker.worker.imageUrl),
                    onBackgroundImageError: (_, __) {},
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color.fromARGB(255, 77, 196, 81),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
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
              return DropdownMenuItem(value: year, child: Text('$year'));
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
