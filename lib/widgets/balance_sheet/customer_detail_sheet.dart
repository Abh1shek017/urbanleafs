import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/due_provider.dart';
import '../../../screens/customer/customer_detail_screen.dart';

DateTime getOrderTime(dynamic orderTime) {
  if (orderTime is Timestamp) {
    return orderTime.toDate();
  } else if (orderTime is DateTime) {
    return orderTime;
  }
  return DateTime.now();
}

void showDueCustomersBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Customers with Outstanding Dues',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final allCustomersAsync = ref.watch(
                        allCustomersWithDueProvider,
                      );

                      return allCustomersAsync.when(
                        data: (customers) {
                          if (customers.isEmpty) {
                            return const Center(
                              child: Text('No customers found.'),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: customers.length,
                            itemBuilder: (context, index) {
                              final customer = customers[index];
                              final due = customer.totalDue;
                              final cardColor = due <= 0
                                  ? Colors.grey[100]
                                  : due < 1000
                                  ? Colors.green[100]
                                  : due < 5000
                                  ? Colors.orange[100]
                                  : Colors.red[100];

                              return Card(
                                color: cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading:
                                      customer.profileImageUrl?.isNotEmpty ==
                                          true
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            customer.profileImageUrl!,
                                          ),
                                        )
                                      : const CircleAvatar(
                                          child: Icon(Icons.person),
                                        ),
                                  title: Text(
                                    customer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '📞 ${customer.phone}\n🏠 ${customer.address}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Text(
                                    '₹${due.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerDetailScreen(
                                          customer: customer,
                                          payments: customer.payments,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
