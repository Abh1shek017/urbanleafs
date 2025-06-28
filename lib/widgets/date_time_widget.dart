import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeWidget extends StatefulWidget {
  final Function(DateTime)? onDayChange;

  const DateTimeWidget({super.key, this.onDayChange});

  @override
  State<DateTimeWidget> createState() => _DateTimeWidgetState();
}

class _DateTimeWidgetState extends State<DateTimeWidget> {
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _startClock();
  }

  void _startClock() {
    Future.delayed(const Duration(seconds: 1), () {
      final now = DateTime.now();
      if (widget.onDayChange != null &&
          (now.day != _currentTime.day ||
              now.month != _currentTime.month ||
              now.year != _currentTime.year)) {
        widget.onDayChange!(now);
      }

      setState(() {
        _currentTime = now;
      });

      _startClock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE').format(_currentTime); // e.g. Monday
    final fullDate = DateFormat('dd MMMM yyyy').format(_currentTime); // e.g. 17 June 2025
    final time = DateFormat('hh:mm a').format(_currentTime); // e.g. 07:35 PM

    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Text(
                dayName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 8, 136, 78),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fullDate,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
