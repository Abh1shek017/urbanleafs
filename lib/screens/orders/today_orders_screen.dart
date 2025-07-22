import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import 'add_order_screen.dart'; // Your reusable form widget

class TodayOrdersScreen extends ConsumerWidget {
  const TodayOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(todaysOrdersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Orders")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: AddOrderCard(), // The embedded reusable form
            ),
            ordersAsync.when(
              loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(child: Text('Error: $err')),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text('No orders found today.')),
                  );
                }

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(order.orderTime);
                    final amount = (order.totalAmount).toDouble(); // ✅ Safe cast

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("Item: ${order.description}"),
                            Text("Qty: ${order.quantity}"),
                            Text("Price: ₹${amount.toStringAsFixed(2)}"), // ✅ Safe usage
                            Text("Time: $formattedDate",
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
