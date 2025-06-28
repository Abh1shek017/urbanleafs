import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Edit your personal details", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: "Full Name"),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "Email Address"),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Save logic here
              },
              child: Text("Save Changes"),
            )
          ],
        ),
      ),
    );
  }
}