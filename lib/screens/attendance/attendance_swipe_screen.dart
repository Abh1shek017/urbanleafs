import 'package:flutter/material.dart';
import 'daily_attendance_shift_page.dart';
import '../../constants/app_constants.dart';
import '../../widgets/keep_alive_wrapper.dart';
import 'package:urbanleafs/utils/capitalize.dart';

class AttendanceSwipeScreen extends StatefulWidget {
  const AttendanceSwipeScreen({super.key});

  @override
  State<AttendanceSwipeScreen> createState() => _AttendanceSwipeScreenState();
}

class _AttendanceSwipeScreenState extends State<AttendanceSwipeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<String> shifts = [
    AppConstants.shiftMorning,
    AppConstants.shiftAfternoon,
  ];

  @override
  Widget build(BuildContext context) {
    final currentShiftName = shifts[_currentIndex].capitalize();

    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Attendance - $currentShiftName Shift"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                shifts.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Text(shifts[index].capitalize()),
                    selected: _currentIndex == index,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _currentIndex = index);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: shifts.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return KeepAliveWrapper(
                  child: DailyAttendanceShiftPage(shift: shifts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
