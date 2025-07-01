import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/master_data_service.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../utils/notifications_util.dart';

class AddOrderCard extends ConsumerStatefulWidget {
  const AddOrderCard({super.key});

  @override
  ConsumerState<AddOrderCard> createState() => _AddOrderCardState();
}

class _AddOrderCardState extends ConsumerState<AddOrderCard> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomer;
  String? _selectedItem;
  int _quantity = 1;
  double _price = 0.0;
  final TextEditingController _priceController = TextEditingController();
  final masterDataService = MasterDataService();

  List<String> _customerList = [];
  List<String> _itemList = [];
  bool _loading = true;

  double get _total => _quantity * _price;

  @override
  void initState() {
    super.initState();
    _priceController.text = _price.toStringAsFixed(2);
    _loadMasterData();
  }
Future<void> _loadMasterData() async {
  // print("➡️ Start loading local JSON");

  final sw = Stopwatch()..start();
  final data = await masterDataService.loadLocalMasterData();
  sw.stop();
  // print("✅ Loaded JSON in ${sw.elapsedMilliseconds} ms: $data");

  final customers = data['customers'] ?? [];
  final items = data['orderItems'] ?? [];

  if (mounted) {
    setState(() {
      _customerList = customers.map<String>((e) => e.toString()).toList();
      _itemList = items.map<String>((e) => e.toString()).toList();
      _loading = false;
    });
    // print("🎯 Dropdowns updated: customers $_customerList items $_itemList");
  }
}


  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedCustomer = null;
      _selectedItem = null;
      _quantity = 1;
      _price = 0.0;
      _priceController.text = '0.00';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Customer Name'),
                      value: _selectedCustomer,
                      items: _customerList.map((name) {
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: _customerList.isEmpty
                          ? null
                          : (value) => setState(() => _selectedCustomer = value),
                      validator: (value) => value == null ? 'Please select a customer' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Item'),
                            value: _selectedItem,
                            items: _itemList.map((item) {
                              return DropdownMenuItem(value: item, child: Text(item));
                            }).toList(),
                            onChanged: _itemList.isEmpty
                                ? null
                                : (value) => setState(() => _selectedItem = value),
                            validator: (value) => value == null ? 'Please select an item' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: _quantity.toString(),
                            decoration: const InputDecoration(labelText: 'Qty'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                                return 'Valid';
                              }
                              return null;
                            },
                            onChanged: (val) => setState(() {
                              _quantity = int.tryParse(val) ?? 1;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Price per Item'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onTap: () {
                              _priceController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _priceController.text.length,
                              );
                            },
                            validator: (value) {
                              if (value == null ||
                                  double.tryParse(value) == null ||
                                  double.parse(value) < 0) {
                                return 'Enter valid price';
                              }
                              return null;
                            },
                            onChanged: (val) => setState(() {
                              _price = double.tryParse(val) ?? 0.0;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Total'),
                            child: Text(
                              '₹${_total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              final userId = "temp_user_id"; // TODO: real UID
                              final orderData = {
                                'description': _selectedItem,
                                'quantity': _quantity,
                                'totalPrice': _total,
                                'customerName': _selectedCustomer,
                                'orderTime': Timestamp.now(),
                                'addedBy': userId,
                              };

                              await ref.read(addOrderFutureProvider(orderData).future);

                              await addNotification(
                                title: 'New Order',
                                body:
                                    'Order for $_selectedItem ($_quantity pcs) by $_selectedCustomer',
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Order added successfully'),
                                  ),
                                );
                                _resetForm();
                              }
                            }
                          },
                          child: const Text('Add Order'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                          ),
                          onPressed: _resetForm,
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.black87),
                          ),
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
