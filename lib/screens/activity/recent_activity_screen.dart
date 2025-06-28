import 'package:flutter/material.dart';
import '../../utils/format_utils.dart';

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ActivityItem> activityList = [
      ActivityItem(
        title: "Added Expense",
        description: "₹2500 - Raw Material",
        time: DateTime.now().subtract(Duration(minutes: 15)),
      ),
      ActivityItem(
        title: "Marked Attendance",
        description: "Rajesh Kumar - Morning Shift",
        time: DateTime.now().subtract(Duration(minutes: 45)),
      ),
      ActivityItem(
        title: "Inventory Updated",
        description: "Plates - +1000 pcs",
        time: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Recent Activity")),
      body: ListView.builder(
        itemCount: activityList.length,
        itemBuilder: (context, index) {
          final item = activityList[index];
          return ListTile(
            leading: Icon(Icons.history),
            title: Text(item.title),
            subtitle: Text(item.description),
            trailing: Text(FormatUtils.formatTime(item.time)),
          );
        },
      ),
    );
  }
}

class ActivityItem {
  final String title;
  final String description;
  final DateTime time;

  ActivityItem({
    required this.title,
    required this.description,
    required this.time,
  });
}