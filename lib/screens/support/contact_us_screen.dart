import 'package:flutter/material.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Contact Us")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("For support or feedback:", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Text("Email: abhishek.paperplate@gmail.com"),
            Text("Phone: +91 98765 43210"),
            Text("Address: UrbanLeafs Pvt Ltd, Delhi"),
          ],
        ),
      ),
    );
  }
}