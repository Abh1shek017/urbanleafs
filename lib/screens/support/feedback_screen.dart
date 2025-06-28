import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Send us your feedback", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: "Write your feedback here...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Submit logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Feedback sent")),
                );
              },
              child: Text("Submit Feedback"),
            ),
          ],
        ),
      ),
    );
  }
}