import 'package:flutter/material.dart';
// import 'package:urbanleafs/utils/format_utils.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Legal")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text("Privacy Policy"),
            subtitle: Text("Your privacy policy content goes here..."),
            onTap: () => _showLegalDialog(
              context,
              "Privacy Policy",
              "Full privacy policy text...",
            ),
          ),
          ListTile(
            title: Text("Terms of Service"),
            subtitle: Text("Read our terms and conditions"),
            onTap: () => _showLegalDialog(
              context,
              "Terms of Service",
              "Full TOS text...",
            ),
          ),
          ListTile(
            title: Text("Data Export"),
            subtitle: Text("Export your records"),
            onTap: () {
              // Implement export logic
            },
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
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
