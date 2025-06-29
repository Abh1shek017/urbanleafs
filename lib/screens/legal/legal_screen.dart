import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/legl_widget_item.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Legal & Compliance")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("About App"),
            onTap: () => context.pushNamed('app_info'),
          ),
          ListTile(
            title: const Text("Privacy Policy"),
            onTap: () => context.pushNamed('privacy_policy'),
          ),
          ListTile(
            title: const Text("Terms of Service"),
            onTap: () => context.pushNamed('terms_of_service'),
          ),
          Divider(height: 1),
          LegalMenuItem(
            title: "Data Export",
            subtitle: "Export your personal data anytime",
            onTap: () => _showDataExportDialog(context),
          ),
        ],
      ),
    );
  }

  void _showDataExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Data Export"),
        content: Text(
          "You can export your data as JSON or CSV. This feature will be available in a future update.",
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
}
