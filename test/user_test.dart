import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TestUploadScreen extends StatefulWidget {
  const TestUploadScreen({super.key});

  @override
  State<TestUploadScreen> createState() => _TestUploadScreenState();
}

class _TestUploadScreenState extends State<TestUploadScreen> {
  String? _result;
  bool _isLoading = false;

  Future<void> _uploadTest() async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) {
      setState(() => _result = '🚨 User not logged in!');
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        setState(() => _result = '🚫 No image selected');
        return;
      }

      final uid = auth.uid;
      final path = 'users_images/profile_${uid}.jpg';
      final file = File(pickedFile.path);

      setState(() {
        _isLoading = true;
        _result = '📂 Uploading to: $path';
      });

      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(file);

      final url = await ref.getDownloadURL();
      setState(() => _result = '✅ Upload successful!\n\nURL:\n$url');
    } catch (e) {
      setState(() => _result = '❌ Failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Upload")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadTest,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Upload Test Image"),
            ),
            const SizedBox(height: 24),
            if (_isLoading) const CircularProgressIndicator(),
            if (_result != null) Text(_result!),
          ],
        ),
      ),
    );
  }
}
