import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FAQs")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ExpansionTile(
            title: Text("What is this app for?"),
            children: [
              ListTile(
                title: Text("This app helps manage paper plate business operations like attendance, inventory, expenses, etc."),
              )
            ],
          ),
          ExpansionTile(
            title: Text("Who can edit past expenses?"),
            children: [
              ListTile(
                title: Text("Only Admin can edit past entries. Regular Users can only add today's expense."),
              )
            ],
          ),
          ExpansionTile(
            title: Text("Can I export my data?"),
            children: [
              ListTile(
                title: Text("Yes, go to Settings → Legal & Compliance → Export My Data"),
              )
            ],
          ),
        ],
      ),
    );
  }
}