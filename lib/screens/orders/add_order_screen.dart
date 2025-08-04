import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urbanleafs/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class AddOrderCard extends ConsumerStatefulWidget {
  const AddOrderCard({super.key});

  @override
  ConsumerState<AddOrderCard> createState() => _AddOrderCardState();
}

class _AddOrderCardState extends ConsumerState<AddOrderCard> {
  final _formKey = GlobalKey<FormState>();

  List<String> _customerList = [];
  List<Map<String, dynamic>> _itemList = [];

  String? _selectedCustomer;
  Map<String, dynamic>? _selectedItem;

  String sanitize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  int _quantity = 1;
  double _price = 0.0;
  double _amountPaid = 0.0;
  double _totalAmount = 0.0;
  String _paymentStatus = 'Unpaid';
  bool _loading = false;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _fetchPreparedItems();
  }

  Future<void> _fetchCustomers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('customers')
        .get();
    setState(() {
      _customerList = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
    });
  }

  Future<void> _fetchPreparedItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('inventory')
        .where('type', isEqualTo: 'Prepared')
        .get();

    setState(() {
      _itemList = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'name': doc['itemName'],
              'quantity': doc['quantity'],
              // 'price': doc['price'],
            },
          )
          .toList();
    });
  }

  void _calculateTotalAmount() {
    setState(() {
      _totalAmount = _quantity * _price;
    });
  }

  void _updatePaymentStatus() {
    if (_amountPaid >= _totalAmount) {
      _paymentStatus = 'Paid';
    } else if (_amountPaid == 0) {
      _paymentStatus = 'Unpaid';
    } else {
      _paymentStatus = 'Partially Paid';
    }
  }

  bool get _isOrderValid {
    if (_selectedItem == null) return false;
    final availableQty = (_selectedItem!['quantity'] as num).toDouble();
    return _quantity <= availableQty;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() || !_isOrderValid) return;

    final customerName = _selectedCustomer;
    final itemName = _selectedItem!['name'];
    final itemId = _selectedItem!['id'];

    setState(() => _loading = true);

    try {
      // Get customer document ID
      final customerSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('name', isEqualTo: customerName)
          .limit(1)
          .get();

      if (customerSnapshot.docs.isEmpty) {
        throw Exception('Customer not found');
      }

      final customerDoc = customerSnapshot.docs.first.reference;

      // Generate order ID
      final now = DateTime.now();
      final orderId =
          '${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}_${sanitize(_selectedCustomer!)}_${sanitize(itemName)}';

      final authState = ref.read(authStateProvider).value;
      String _addedBy = authState?.uid ?? 'Unknown';

      await customerDoc.collection('orders').doc(orderId).set({
        'item': itemName,
        'quantity': _quantity,
        'price': _price,
        'totalAmount': _totalAmount,
        'orderTime': now,
        'paymentStatus': _paymentStatus,
        'addedBy': _addedBy,
        'customerName': _selectedCustomer,
        'amountPaid': _amountPaid,
      });

      // Add payment

      // Clean up values for ID
      final formattedDate =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final cleanedCustomerName = (customerName ?? '').replaceAll(' ', '');
      final paymentId =
          '${_paymentStatus}_${_amountPaid.toInt()}_${cleanedCustomerName}_$formattedDate';

      await customerDoc.collection('payments').doc(paymentId).set({
        'paymentId': paymentId,
        'customerId': customerDoc.id,
        'customerName': _selectedCustomer,
        'amount':
            _amountPaid, // 👈 This is the correct field name (not amountPaid)
        'totalAmount': _totalAmount,
        'status': _paymentStatus,
        'note': 'Auto-payment for order $orderId',
        'receivedBy': _addedBy, // 👈 Now stores the actual user ID (uid)
        'receivedTime': now,
        'timestamp': now, // Optional: Keep for sorting or historical tracking
      });

      // Deduct inventory quantity
      final currentQty = (_selectedItem!['quantity'] as num).toDouble();
      final newQty = currentQty - _quantity;

      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(itemId)
          .update({'quantity': newQty});

      final sanitizedItemName = itemName.replaceAll(' ', '_');
      final formatteddate = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(now).substring(0, 15); // trims to 2-digit seconds
      final customId = '${sanitizedItemName}_order_${_quantity}_$formatteddate';

      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(itemId)
          .collection('history')
          .doc(customId)
          .set({
            'quantity': _quantity,
            'type': 'used',
            'reason': 'Order placed by $_selectedCustomer',
            'relatedOrderId': orderId,
            'timestamp': Timestamp.fromDate(now),
            'addedBy': _addedBy,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      // Reset form
      setState(() {
        _selectedItem = null;
        _quantity = 1;
        _priceController.clear();
        _amountPaidController.clear();
        _price = 0.0;
        _totalAmount = 0.0;
        _amountPaid = 0.0;
        _paymentStatus = 'Unpaid';
      });

      _fetchPreparedItems();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// 1. Customer Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(labelText: 'Customer'),
                      items: _customerList
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCustomer = val),
                      validator: (val) =>
                          val == null ? 'Select a customer' : null,
                    ),

                    const SizedBox(height: 16),

                    /// 2. Item Dropdown with quantity
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedItem,
                      decoration: const InputDecoration(
                        labelText: 'Item (Available)',
                      ),
                      items: _itemList
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                '${item['name']} (Qty: ${item['quantity']})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedItem = val;
                          _price = (val?['price'] ?? 0.0).toDouble();
                          _priceController.text = _price.toString();
                          _calculateTotalAmount();
                          _updatePaymentStatus();
                        });
                      },
                      validator: (val) => val == null ? 'Select an item' : null,
                    ),

                    const SizedBox(height: 16),

                    /// 3. Quantity & Price per item (side by side)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '1',
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              _quantity = int.tryParse(val) ?? 1;
                              _calculateTotalAmount();
                              _updatePaymentStatus();
                              setState(() {});
                            },
                            validator: (val) {
                              final qty = int.tryParse(val ?? '');
                              if (qty == null || qty <= 0)
                                return 'Invalid quantity';
                              if (!_isOrderValid) return 'Exceeds stock';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price per item',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (val) {
                              _price = double.tryParse(val) ?? 0.0;
                              _calculateTotalAmount();
                              _updatePaymentStatus();
                            },
                            onTap: () {
                              // Auto-select the entire text when tapped
                              _priceController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _priceController.text.length,
                              );
                            },
                            validator: (val) {
                              final price = double.tryParse(val ?? '');
                              if (price == null || price <= 0) {
                                return 'Price must be greater than 0';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// 4. Total amount (read only) & Amount paid (editable)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Total Amount',
                              filled: true,
                              fillColor: Colors.grey.shade200,
                            ),
                            controller: TextEditingController(
                              text: _totalAmount.toStringAsFixed(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _amountPaidController,
                            decoration: const InputDecoration(
                              labelText: 'Amount Paid',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (val) {
                              _amountPaid = double.tryParse(val) ?? 0.0;
                              _updatePaymentStatus();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// 5. Payment status (read only) and Add Order Button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Payment Status',
                              filled: true,
                              fillColor: Colors.grey.shade200,
                            ),
                            controller: TextEditingController(
                              text: _paymentStatus,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isOrderValid ? _submitOrder : null,
                          child: const Text('Add Order'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
