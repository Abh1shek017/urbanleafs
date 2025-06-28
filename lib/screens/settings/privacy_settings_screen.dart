import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Privacy Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text("Allow Location Tracking"),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Auto-Sync Data"),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text("Data Sharing Enabled"),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
}