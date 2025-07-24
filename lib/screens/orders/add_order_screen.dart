import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddOrderCard extends StatefulWidget {
  const AddOrderCard({super.key});

  @override
  State<AddOrderCard> createState() => _AddOrderCardState();
}

class _AddOrderCardState extends State<AddOrderCard> {
  final _formKey = GlobalKey<FormState>();

  List<String> _customerList = [];
  List<Map<String, dynamic>> _itemList = [];

  String? _selectedCustomer;
  Map<String, dynamic>? _selectedItem;

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
    final snapshot = await FirebaseFirestore.instance.collection('customers').get();
    setState(() {
      _customerList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> _fetchPreparedItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('inventory')
        .where('type', isEqualTo: 'PREPARED')
        .get();

    setState(() {
      _itemList = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
                'quantity': doc['quantity'],
                'price': doc['price'],
              })
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
    final availableQty = _selectedItem!['quantity'] as int;
    return _quantity <= availableQty;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() || !_isOrderValid) return;

    final customerName = _selectedCustomer!;
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
      final orderId = '${itemName}_${customerName}_${now.millisecondsSinceEpoch}';

      // Add order
      await customerDoc.collection('orders').doc(orderId).set({
        'item': itemName,
        'quantity': _quantity,
        'price': _price,
        'totalAmount': _totalAmount,
        'timestamp': now,
        'paymentStatus': _paymentStatus,
      });

      // Add payment
      await customerDoc.collection('payments').add({
        'amount': _amountPaid,
        'status': _paymentStatus,
        'timestamp': now,
        'note': 'Auto-payment for order $orderId',
      });

      // Deduct inventory quantity
      final newQty = (_selectedItem!['quantity'] as int) - _quantity;
      await FirebaseFirestore.instance.collection('inventory').doc(itemId).update({
        'quantity': newQty,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCustomer = val),
                      validator: (val) => val == null ? 'Select a customer' : null,
                    ),

                    const SizedBox(height: 16),

                    /// 2. Item Dropdown with quantity
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedItem,
                      decoration: const InputDecoration(labelText: 'Item (Available)'),
                      items: _itemList
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text('${item['name']} (Qty: ${item['quantity']})'),
                              ))
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
                            decoration: const InputDecoration(labelText: 'Quantity'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              _quantity = int.tryParse(val) ?? 1;
                              _calculateTotalAmount();
                              _updatePaymentStatus();
                              setState(() {});
                            },
                            validator: (val) {
                              final qty = int.tryParse(val ?? '');
                              if (qty == null || qty <= 0) return 'Invalid quantity';
                              if (!_isOrderValid) return 'Exceeds stock';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Price per item'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (val) {
                              _price = double.tryParse(val) ?? 0.0;
                              _calculateTotalAmount();
                              _updatePaymentStatus();
                            },
                            validator: (val) {
                              final price = double.tryParse(val ?? '');
                              if (price == null || price < 0) return 'Invalid price';
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
                            controller: TextEditingController(text: _totalAmount.toStringAsFixed(2)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _amountPaidController,
                            decoration: const InputDecoration(labelText: 'Amount Paid'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                            controller: TextEditingController(text: _paymentStatus),
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
