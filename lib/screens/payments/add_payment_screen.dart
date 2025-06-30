import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/json_storage_service.dart';
import '../../providers/payment_provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/notifications_provider.dart';

class AddPaymentCard extends ConsumerStatefulWidget {
  final String userId;
  const AddPaymentCard({super.key, required this.userId});

  @override
  ConsumerState<AddPaymentCard> createState() => _AddPaymentCardState();
}

class _AddPaymentCardState extends ConsumerState<AddPaymentCard> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCustomer;
  String _paymentType = AppConstants.paymentCash;

  final jsonStorage = JsonStorageService();
  List<String> _customerList = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await jsonStorage.getField('customers') as List<dynamic>;
    setState(() {
      _customerList = customers.map((e) => e.toString()).toList();
    });
  }

  void _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.trim());
      final repo = ref.read(paymentRepositoryProvider);

      await repo.addPayment({
        'amount': amount,
        'customerName': _selectedCustomer!,
        'receivedTime': DateTime.now(),
        'receivedBy': widget.userId,
        'type': _paymentType,
      });

      await ref.read(
        createNotificationProvider({
          'title': 'Payment Received',
          'body':
              '₹${amount.toStringAsFixed(2)} from $_selectedCustomer ($_paymentType)',
        }),
      );

      setState(() {
        _amountController.clear();
        _selectedCustomer = null;
        _paymentType = AppConstants.paymentCash;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment added successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCustomer,
                hint: const Text("Select Customer"),
                items: _customerList
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCustomer = val),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select a customer' : null,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Enter amount';
                        }
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentType,
                      items: [AppConstants.paymentCash, AppConstants.paymentOnline]
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) => setState(
                          () => _paymentType = val ?? AppConstants.paymentCash),
                      decoration: const InputDecoration(labelText: 'Mode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitPayment,
                child: const Text('Add Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
