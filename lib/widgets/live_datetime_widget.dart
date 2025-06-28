import 'package:flutter/material.dart';
import 'package:urbanleafs/utils/app_date_utils.dart';
import 'package:intl/intl.dart';

class LiveDateTimeWidget extends StatefulWidget {
  const LiveDateTimeWidget({super.key});

  @override
  State<LiveDateTimeWidget> createState() => _LiveDateTimeWidgetState();
}

class _LiveDateTimeWidgetState extends State<LiveDateTimeWidget> {
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _startClock();
  }

  void _startClock() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _currentTime = DateTime.now();
      });
      _startClock();
    });
  }

  String getFormattedDateTime(DateTime time) {
    String dayName = DateFormat('EEEE').format(time); // Saturday
    String date = AppDateUtils.formatDate(time); // 15 June 2025
    String clock = AppDateUtils.formatTime(time); // 09:42 PM
    return "$dayName, $date • $clock";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Text(
                getFormattedDateTime(_currentTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.right,
                softWrap: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
