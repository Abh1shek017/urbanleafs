import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/notifications_util.dart';

class AddNotificationsScreen extends ConsumerStatefulWidget {
  const AddNotificationsScreen({super.key});

  @override
  ConsumerState<AddNotificationsScreen> createState() =>
      _AddNotificationsScreenState();
}

class _AddNotificationsScreenState
    extends ConsumerState<AddNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'general';

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await addNotification(_type, _titleController.text, _bodyController.text);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Notification")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) => value!.isEmpty ? "Enter a title" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(labelText: "Body"),
                validator: (value) => value!.isEmpty ? "Enter body text" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'orders', child: Text("Orders")),
                  DropdownMenuItem(value: 'expenses', child: Text("Expenses")),
                  DropdownMenuItem(value: 'payments', child: Text("Payments")),
                  DropdownMenuItem(value: 'general', child: Text("General")),
                ],
                onChanged: (val) => setState(() => _type = val!),
                decoration: const InputDecoration(labelText: "Type"),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send),
                label: const Text("Add Notification"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
