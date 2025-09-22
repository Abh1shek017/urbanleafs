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

class EditCustomerScreen extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const EditCustomerScreen({super.key, required this.customer});

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}
class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController shopCtrl; // <-- Added shop controller
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController gstCtrl;

  File? _selectedImage;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.customer.name);
    shopCtrl = TextEditingController(text: widget.customer.shopName); // <-- init
    phoneCtrl = TextEditingController(text: widget.customer.phone);
    addressCtrl = TextEditingController(text: widget.customer.address);
    gstCtrl = TextEditingController(text: widget.customer.gstNumber ?? '');
  }

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
    if (_selectedImage == null) return widget.customer.profileImageUrl;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('customer_profiles/$customerId.jpg');
      final uploadTask = await storageRef.putFile(_selectedImage!);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      setState(() => errorMessage = 'Image upload failed: $e');
      return widget.customer.profileImageUrl;
    }
  }

  Future<String> _fetchUsernameFromUid(String uid) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snapshot.data()?['username'] ?? uid;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final user = ref.read(authStateProvider).value;
      final addedByName = await _fetchUsernameFromUid(user?.uid ?? 'unknown');
      final profileUrl = await _uploadProfilePicture(widget.customer.id);

      final updatedCustomer = CustomerModel(
        id: widget.customer.id,
        name: nameCtrl.text.trim(),
        shopName: shopCtrl.text.trim(), // <-- include shop name
        phone: phoneCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        gstNumber: gstCtrl.text.trim().isEmpty ? null : gstCtrl.text.trim(),
        profileImageUrl: profileUrl,
        addedBy: addedByName,
        createdAt: widget.customer.createdAt,
      );

      await ref.read(updateCustomerProvider)(updatedCustomer);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer updated')),
      );
    } catch (e) {
      setState(() => errorMessage = 'Failed to update customer: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer'), centerTitle: true),
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
                        : (widget.customer.profileImageUrl != null &&
                                widget.customer.profileImageUrl!.isNotEmpty
                            ? NetworkImage(widget.customer.profileImageUrl!)
                            : null) as ImageProvider<Object>?,
                    child: _selectedImage == null &&
                            (widget.customer.profileImageUrl == null ||
                                widget.customer.profileImageUrl!.isEmpty)
                        ? Icon(Icons.add_a_photo, color: Colors.grey.shade600)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              GreenInputField(
                label: "Full Name",
                icon: Icons.person_outline,
                controller: nameCtrl,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Required" : null,
              ),

              GreenInputField(
                label: "Shop Name",   // <-- Added field
                icon: Icons.store_outlined,
                controller: shopCtrl,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Required" : null,
              ),

              GreenInputField(
                label: "Mobile Number",
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                controller: phoneCtrl,
                validator: (val) => val == null || val.trim().length != 10
                    ? "Enter 10-digit number"
                    : null,
              ),

              GreenInputField(
                label: "Address",
                icon: Icons.home_outlined,
                controller: addressCtrl,
                maxLines: 2,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Required" : null,
              ),

              GreenInputField(
                label: "GST Number (Optional)",
                icon: Icons.confirmation_number_outlined,
                controller: gstCtrl,
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
                  label: Text(isSubmitting ? "Updating..." : "Update Customer"),
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
