import 'package:flutter/material.dart';
import '../../services/json_storage_service.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  Map<String, dynamic> masterData = {
    "customers": [],
    "inventory_items": [],
    "units": [],
    "item_types": [],
    "order_items": [],
    "expense_types": []
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await JsonStorageService().getMasterData();
    setState(() {
      masterData = data;
    });
  }

  Future<void> _saveData() async {
    await JsonStorageService().updateMasterDataField('customers', masterData['customers']);
  }

  void _addCustomer() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                masterData["customers"].add({
                  "name": nameController.text,
                  "phone": phoneController.text,
                });
              });
              _saveData();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _addItem(String key) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add to ${key.replaceAll('_', ' ').toUpperCase()}"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Value"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                masterData[key].add(controller.text);
              });
              _saveData();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(String key, int index) {
    setState(() {
      masterData[key].removeAt(index);
    });
    _saveData();
  }

  void _deleteCustomer(int index) {
    setState(() {
      masterData["customers"].removeAt(index);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Master Data")),
      body: ListView(
        children: [
          ExpansionTile(
            title: const Text("Manage Customers"),
            children: [
              ...List.generate(masterData["customers"].length, (index) {
                final cust = masterData["customers"][index];
                return ListTile(
                  title: Text(cust["name"]),
                  subtitle: Text(cust["phone"]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCustomer(index),
                  ),
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Customer"),
                onPressed: _addCustomer,
              ),
            ],
          ),
          ExpansionTile(
            title: const Text("Inventory Edits"),
            children: [
              _buildSection("inventory_items"),
              _buildSection("units"),
              _buildSection("item_types"),
            ],
          ),
          ExpansionTile(
            title: const Text("Orders Edit"),
            children: [
              _buildSection("order_items"),
            ],
          ),
          ExpansionTile(
            title: const Text("Expenses Edit"),
            children: [
              _buildSection("expense_types"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String key) {
    return Column(
      children: [
        ...List.generate(masterData[key].length, (index) => ListTile(
              title: Text(masterData[key][index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteItem(key, index),
              ),
            )),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text("Add ${key.replaceAll('_', ' ')}"),
          onPressed: () => _addItem(key),
        )
      ],
    );
  }
}
