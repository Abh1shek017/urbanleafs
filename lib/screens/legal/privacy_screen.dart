import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Privacy Policy")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Your privacy policy goes here.\n\n"
          "This app does not collect any personally identifiable information beyond what is required to run the business management features.\n\n"
          "Users are allowed to request their data at any time via Data Export.\n\n"
          "We do not share your data with third parties.\n\n"
          "By using this app, you agree to these terms.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}