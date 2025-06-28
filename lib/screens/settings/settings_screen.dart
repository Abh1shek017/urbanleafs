import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: Text("General Settings"),
            onTap: () => Navigator.pushNamed(context, '/settings/general'),
          ),
          ListTile(
            title: Text("Notifications"),
            onTap: () => Navigator.pushNamed(context, '/settings/notifications'),
          ),
          ListTile(
            title: Text("Privacy Settings"),
            onTap: () => Navigator.pushNamed(context, '/settings/privacy'),
          ),
          ListTile(
            title: Text("Language Selection"),
            onTap: () => Navigator.pushNamed(context, '/settings/language'),
          ),
          ListTile(
            title: Text("Appearance"),
            onTap: () => Navigator.pushNamed(context, '/settings/appearance'),
          ),
        ],
      ),
    );
  }
}