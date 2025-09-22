import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/input_fields.dart'; // GreenInputField

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String phone = '';
  String address = '';
  String gst = '';
  File? _selectedImage;
  bool isSubmitting = false;
  String? errorMessage;
  String shopName = '';

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadProfilePicture(String customerId) async {
    if (_selectedImage == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'customer_images/$customerId.jpg',
      );
      final uploadTask = await storageRef.putFile(_selectedImage!);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      setState(() => errorMessage = 'Image upload failed: $e');
      return null;
    }
  }

  Future<String> _fetchUsernameFromUid(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return snapshot.data()?['username'] ?? uid;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final customerId =
          '${name.trim().replaceAll(' ', '_').toLowerCase()}_${phone.trim().substring(phone.trim().length - 5)}';
      final user = ref.read(authStateProvider).value;
      final addedByName = await _fetchUsernameFromUid(user?.uid ?? 'unknown');
      final profileUrl = await _uploadProfilePicture(customerId);

      final newCustomer = CustomerModel(
        id: customerId,
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        gstNumber: gst.trim().isEmpty ? null : gst.trim(),
        profileImageUrl: profileUrl,
        addedBy: addedByName,
        shopName: shopName.trim(), // ← new field
        createdAt: Timestamp.now(),
      );

      await ref.read(addCustomerProvider)(newCustomer);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => errorMessage = 'Failed to add customer: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer'), centerTitle: true),
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
                label: "Shop Name",
                icon: Icons.store_outlined,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Required" : null,
                onSaved: (val) => shopName = val!,
              ),

              GreenInputField(
                label: "Mobile Number",
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().length != 10
                    ? "Enter 10-digit number"
                    : null,
                onSaved: (val) => phone = val!,
              ),

              GreenInputField(
                label: "Address",
                icon: Icons.home_outlined,
                maxLines: 2,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Required" : null,
                onSaved: (val) => address = val!,
              ),

              GreenInputField(
                label: "GST Number (Optional)",
                icon: Icons.confirmation_number_outlined,
                onSaved: (val) => gst = val ?? '',
              ),

              const SizedBox(height: 16),
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
                  label: Text(isSubmitting ? "Saving..." : "Add Customer"),
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
