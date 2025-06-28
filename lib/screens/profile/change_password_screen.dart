import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Current Password"),
            ),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: "New Password"),
            ),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Confirm New Password"),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Add password change logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Password changed successfully")),
                );
              },
              child: Text("Change Password"),
            )
          ],
        ),
      ),
    );
  }
}