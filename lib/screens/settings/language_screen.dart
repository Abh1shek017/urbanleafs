import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Language")),
      body: ListView(
        children: [
          ListTile(
            title: Text("English"),
            trailing: Radio(value: 'en', groupValue: 'en', onChanged: (_) {}),
          ),
          ListTile(
            title: Text("हिन्दी"),
            trailing: Radio(value: 'hi', groupValue: 'en', onChanged: (_) {}),
          ),
          ListTile(
            title: Text("বাংলা"),
            trailing: Radio(value: 'bn', groupValue: 'en', onChanged: (_) {}),
          ),
        ],
      ),
    );
  }
}