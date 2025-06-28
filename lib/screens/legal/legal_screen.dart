import 'package:flutter/material.dart';
import '../../widgets/legl_widget_item.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Legal & Compliance")),
      body: ListView(
        children: [
          LegalMenuItem(
            title: "About This App",
            subtitle: "Learn more about UrbanLeafs Paper Plate Manager",
            onTap: () => Navigator.pushNamed(context, '/legal/about'),
          ),
          Divider(height: 1),
          LegalMenuItem(
            title: "Privacy Policy",
            subtitle: "How we collect and protect your data",
            onTap: () => Navigator.pushNamed(context, '/legal/privacy-policy'),
          ),
          Divider(height: 1),
          LegalMenuItem(
            title: "Terms of Service",
            subtitle: "Rules and conditions for using this app",
            onTap: () => Navigator.pushNamed(context, '/legal/terms-of-service'),
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
        content: Text("You can export your data as JSON or CSV. This feature will be available in a future update."),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text("Close"),
          )
        ],
      ),
    );
  }
}