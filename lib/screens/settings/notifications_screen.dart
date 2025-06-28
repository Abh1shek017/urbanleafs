import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text("Shift Start Alerts"),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Low Stock Alert"),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Daily Summary"),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
}