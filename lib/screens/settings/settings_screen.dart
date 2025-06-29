import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("General Settings"),
            onTap: () => context.pushNamed('general_settings'),
          ),
          ListTile(
            title: const Text("Notifications"),
            onTap: () => context.pushNamed('notifications'),
          ),
          ListTile(
            title: const Text("Privacy Settings"),
            onTap: () => context.pushNamed('privacy_settings'),
          ),
          ListTile(
            title: const Text("Language Selection"),
            onTap: () => context.pushNamed('language_selection'),
          ),
          ListTile(
            title: const Text("Appearance"),
            onTap: () => context.pushNamed('appearance_settings'),
          ),
        ],
      ),
    );
  }
}
