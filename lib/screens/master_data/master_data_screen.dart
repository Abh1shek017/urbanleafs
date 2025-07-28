import 'package:flutter/material.dart';
import '../../services/master_data_service.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  final MasterDataService _service = MasterDataService();
  bool _loading = false;
  Map<String, dynamic> masterData = {
    "inventoryTypes": [],
    "units": [],
    "itemTypes": [],
    "expenseTypes": [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.loadLocalMasterData();
    final allowedKeys = [
      'inventoryTypes',
      'units',
      'itemTypes',
      'expenseTypes',
    ];
    data.removeWhere((key, _) => !allowedKeys.contains(key));
    setState(() {
      masterData = data;
    });
  }

  Future<void> _refreshFromFirestore() async {
    setState(() => _loading = true);
    await _service.fetchAndUpdateFromFirestore();
    await _loadData();
    setState(() => _loading = false);
  }

  Future<void> _saveData() async {
    // Save all fields to Firebase and local cache
    await _service.updateMasterField(
      'inventoryTypes',
      masterData['inventoryTypes'],
    );
    await _service.updateMasterField('units', masterData['units']);
    await _service.updateMasterField('itemTypes', masterData['itemTypes']);
    await _service.updateMasterField(
      'expenseTypes',
      masterData['expenseTypes'],
    );
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
                masterData["customers"].add(
                  "${nameController.text.trim()} (${phoneController.text.trim()})",
                );
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
        title: Text(
          "Add to ${key.replaceAll(RegExp(r'([A-Z])'), ' \$1').toLowerCase().trim().toUpperCase()}",
        ),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshFromFirestore,
              child: ListView(
                children: [
                  ExpansionTile(
                    title: const Text("Manage Customers"),
                    children: [
                      ...List.generate(masterData["customers"].length, (index) {
                        final cust = masterData["customers"][index];
                        return ListTile(
                          title: Text(cust),
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
                      _buildSection("inventoryTypes"),
                      _buildSection("units"),
                      _buildSection("itemTypes"),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text("Expenses Edit"),
                    children: [_buildSection("expenseTypes")],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String key) {
    return Column(
      children: [
        ...List.generate(
          masterData[key].length,
          (index) => ListTile(
            title: Text(masterData[key][index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(key, index),
            ),
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(
            "Add ${key.replaceAll(RegExp(r'([A-Z])'), ' \$1').toLowerCase().trim()}",
          ),
          onPressed: () => _addItem(key),
        ),
      ],
    );
  }
}
