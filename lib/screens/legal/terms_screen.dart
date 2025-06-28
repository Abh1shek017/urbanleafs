import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Terms of Service")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Terms of Service\n\n"
          "Use of this app is subject to the following terms:\n\n"
          "1. You may only use this app if authorized by Admin.\n"
          "2. All data entered into the app is the responsibility of the user.\n"
          "3. We are not liable for any loss of data unless caused by negligence.\n"
          "4. You may request data deletion at any time.\n"
          "5. App may be updated without notice.\n\n"
          "By using this app, you agree to these terms.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}