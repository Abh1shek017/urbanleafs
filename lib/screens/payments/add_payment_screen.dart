import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../viewmodels/payment_viewmodel.dart';
import '../../models/payment_model.dart';
import '../../providers/customer_provider.dart';

class CustomerEntry {
  final String id;
  final String name;

  CustomerEntry({required this.id, required this.name});
}

class AddPaymentCard extends ConsumerStatefulWidget {
  final String userId;
  const AddPaymentCard({super.key, required this.userId});

  @override
  ConsumerState<AddPaymentCard> createState() => _AddPaymentCardState();
}

class _AddPaymentCardState extends ConsumerState<AddPaymentCard> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCustomerId;
  CustomerEntry? _selectedCustomer;
  String _paymentType = AppConstants.paymentCash;

  bool _loading = true;
  String? _error;
  List<CustomerEntry> _customerList = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // void debugIndex(BuildContext context) async {
  //   try {
  //     final firestore = FirebaseFirestore.instance;
  //     final now = DateTime.now();
  //     final startOfDay = DateTime(now.year, now.month, now.day);
  //     final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  //     final snapshot = await firestore
  //         .collectionGroup('payments')
  //         .where(
  //           'receivedTime',
  //           isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
  //         )
  //         .where(
  //           'receivedTime',
  //           isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
  //         )
  //         .orderBy('receivedTime', descending: true)
  //         .limit(1)
  //         .get();

  //     debugPrint("Index working. Docs found: ${snapshot.docs.length}");
  //   } catch (e) {
  //     debugPrint("🔥 Index error: $e");
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Firestore error: $e")));
  //   }
  // }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();

      final List<CustomerEntry> customers = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unnamed';
        final id = doc.id;

        customers.add(
          CustomerEntry(
            id: id,
            name: name,
          ), // dueAmount will be loaded by provider
        );
      }

      if (!mounted) return;
      setState(() {
        _customerList = customers;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
        return;
      }

      final amountText = _amountController.text.trim();
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      try {
        // Inside your onPressed or submit handler:

        // 1) Build the PaymentModel
        final payment = PaymentModel(
          id: '', // will be set in the repo
          amount: amount,
          customerName: _selectedCustomer!.name,
          receivedTime: DateTime.now(),
          receivedBy: widget.userId,
          type: _paymentType,
          customerId: _selectedCustomer!.id,
          paymentId: '', // will be set in the repo
        );

        final addPaymentProvider = FutureProvider.family<void, PaymentModel>((
          ref,
          payment,
        ) async {
          final repo = ref.watch(paymentRepositoryProvider(payment.customerId));
          await repo.addPayment(payment.customerId, payment);
          setState(() {
            _amountController.clear();
            _selectedCustomer = null;
            _selectedCustomerId = null;
            _paymentType = AppConstants.paymentCash;
          });
        });

        // 2) Call the provider
        await ref.read(addPaymentProvider(payment).future); // ✅ correct
        // Note the () to execute the function

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment added successfully')),
        );
        _loadCustomers(); // refresh due after payment
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add payment: $e')));
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
              if (_loading)
                const LinearProgressIndicator()
              else if (_error != null)
                Column(
                  children: [
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadCustomers,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else if (_customerList.isEmpty)
                const Text('No customers available')
              else
                DropdownButtonFormField<CustomerEntry>(
                  value: _selectedCustomer,
                  hint: const Text("Select Customer"),
                  onChanged: (val) {
                    setState(() {
                      _selectedCustomer = val;
                      _selectedCustomerId = val?.id;
                    });
                  },
                  validator: (val) => val == null ? 'Select a customer' : null,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                  items: _customerList.map((entry) {
                    return DropdownMenuItem<CustomerEntry>(
                      value: entry,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final asyncDue = ref.watch(
                            customerDueAmountProvider(entry.id),
                          );
                          return asyncDue.when(
                            data: (due) => Text(
                              '${entry.name} (₹${due.toStringAsFixed(2)})',
                            ),
                            loading: () => Text('${entry.name} (Loading...)'),
                            error: (_, __) => Text('${entry.name} (Err)'),
                          );
                        },
                      ),
                    );
                  }).toList(),
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
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentType,
                      items:
                          [AppConstants.paymentCash, AppConstants.paymentOnline]
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (val) => setState(() {
                        _paymentType = val ?? AppConstants.paymentCash;
                      }),
                      decoration: const InputDecoration(labelText: 'Mode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading || _error != null || _customerList.isEmpty
                    ? null
                    : _submitPayment,
                child: const Text('Add Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
