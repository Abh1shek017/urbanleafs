import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:urbanleafs/constants/app_constants.dart';
import 'package:urbanleafs/models/worker_model.dart';
import 'package:urbanleafs/providers/worker_provider.dart';
import 'package:urbanleafs/widgets/input_fields.dart';

class AddWorkerScreen extends ConsumerStatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  ConsumerState<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends ConsumerState<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String mobile = '';
  String address = '';
  File? _selectedImage;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String workerId) async {
    try {
      final ext = path.extension(imageFile.path);
      final ref = FirebaseStorage.instance.ref().child(
        'worker_images/$workerId$ext',
      );
      final task = await ref.putFile(imageFile);
      return await task.ref.getDownloadURL();
    } catch (e) {
      setState(() => errorMessage = 'Image upload failed: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    final exists = await ref.read(workerExistsProvider(mobile).future);
    if (exists) {
      setState(() {
        errorMessage = "Worker with this mobile already exists.";
        isSubmitting = false;
      });
      return;
    }

    try {
      final workerId = name.trim().replaceAll(' ', '_').toLowerCase();
      final docRef =
          FirebaseFirestore.instance.collection(AppConstants.collectionWorkers)
          .doc(workerId);

      String imageUrl = '';
      if (_selectedImage != null) {
        final uploaded = await _uploadImage(_selectedImage!, workerId);
        if (uploaded == null) return; // upload failed
        imageUrl = uploaded;
      }

      final newWorker = WorkerModel(
        id: workerId,
        name: name.trim(),
        phone: mobile.trim(),
        address: address.trim(),
        imageUrl: imageUrl,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await docRef.set(newWorker.toMap());

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => errorMessage = 'Failed to add worker: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Worker"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? Icon(Icons.add_a_photo, color: Colors.grey.shade600)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              GreenInputField(
                label: "Full Name",
                icon: Icons.person_outline,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Required" : null,
                onSaved: (val) => name = val!,
              ),

              GreenInputField(
                label: "Mobile Number",
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().length != 10
                    ? "Enter 10-digit number"
                    : null,
                onSaved: (val) => mobile = val!,
              ),

              GreenInputField(
                label: "Address",
                icon: Icons.home_outlined,
                maxLines: 2,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Required" : null,
                onSaved: (val) => address = val!,
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _submit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(isSubmitting ? "Saving..." : "Add Worker"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
