import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer_model.dart';
import '../../utils/staggered_animation.dart';
import '../../widgets/glass_cards.dart';
import '../../widgets/admin_checker.dart';
import '../customer/add_customer_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../customer/edit_customer_screen.dart';

class ManageCustomersScreen extends StatefulWidget {
  const ManageCustomersScreen({super.key});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  List<CustomerModel> _customers = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

 Future<void> _loadCustomers() async {
  final snapshot = await _firestore.collection('customers').get();
  final customers = snapshot.docs
      .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
      .toList();

  setState(() => _customers = customers);

  // When writing to JSON, convert Timestamp to ISO string
  final jsonFile = File(
    '${(await getApplicationDocumentsDirectory()).path}/customers.json',
  );

  final jsonList = customers.map((e) {
    final map = e.toMap();
    // Convert Timestamp to string for JSON only
    map['createdAt'] = map['createdAt'] is Timestamp
        ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
        : map['createdAt'];
    return map;
  }).toList();

  await jsonFile.writeAsString(jsonEncode(jsonList));
}


Future<void> _deleteCustomer(String id) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Customer'),
      content: const Text('Are you sure you want to delete this customer? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (shouldDelete == true) {
    try {
      await _firestore.collection('customers').doc(id).delete();
      await _storage.ref().child('customer_images/profile_$id.jpg').delete().catchError((_) {});
      await _loadCustomers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting customer: $e')),
      );
    }
  }
}

void _launchPhoneCall(String phoneNumber) async {
  final uri = Uri(scheme: 'tel', path: phoneNumber);

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // ensures the dialer app opens
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch phone dialer')),
    );
  }
}


  void _openEditScreen(CustomerModel customer) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditCustomerScreen(customer: customer),
    ),
  );
  await _loadCustomers();
}


  @override
  Widget build(BuildContext context) {
    return AdminChecker(
      builder: (context, isAdmin) {
        return Scaffold(
          appBar: AppBar(title: const Text("Manage Customers")),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddCustomerScreen(),
                      ),
                    );
                    await _loadCustomers();
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: _loadCustomers,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _customers.length,
              itemBuilder: (ctx, i) {
                final customer = _customers[i];
                return StaggeredItem(
                  index: i,
                  child: GlassCard(
  child: Padding(
    padding: const EdgeInsets.all(12.0), // add inner padding
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 40, // bigger size
          backgroundColor: Colors.grey[300],
          child: (customer.profileImageUrl != null &&
                  customer.profileImageUrl!.isNotEmpty)
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: customer.profileImageUrl!,
                    fit: BoxFit.cover,
                    width: 80,  // match radius * 2
                    height: 80,
                    errorWidget: (context, url, error) =>
                        const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black54,
                        ),
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.black54,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              // Shop name
              Text(
                 customer.shopName.isNotEmpty 
      ? customer.shopName 
      : 'Shop Name not set',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _launchPhoneCall(customer.phone),
                child: Text(
                  customer.phone,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              if (customer.gstNumber != null &&
                  customer.gstNumber!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("GST: ${customer.gstNumber}"),
                ),
              Text(customer.address),
            ],
          ),
        ),
        if (isAdmin)
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Colors.green,
                ),
                onPressed: () => _openEditScreen(customer),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                onPressed: () => _deleteCustomer(customer.id),
              ),
            ],
          ),
      ],
    ),
  ),
),

                );
              },
            ),
          ),
        );
      },
    );
  }
}
