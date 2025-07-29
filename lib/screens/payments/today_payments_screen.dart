import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../viewmodels/payment_viewmodel.dart';
import 'add_payment_screen.dart';
import '../customer/add_customer_screen.dart';

class TodayPaymentsScreen extends ConsumerWidget {
  const TodayPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allTodaysPaymentsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Collection")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (user != null)
              AddPaymentCard(userId: user.uid), // Add Payment section

            paymentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading payments: $err'),
              ),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No payments found today.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final formattedTime = DateFormat(
                      'hh:mm a',
                    ).format(payment.receivedTime);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final userNameAsync = ref.watch(
                            userNameByIdProvider(payment.receivedBy),
                          );

                          return ListTile(
                            title: Text(payment.customerName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount: ₹${payment.amount.toStringAsFixed(2)}',
                                ),
                                Text('Received at: $formattedTime'),
                                Text('Mode: ${payment.type}'),
                                userNameAsync.when(
                                  data: (name) => Text('Added by: $name'),
                                  loading: () => const Text('Added by: ...'),
                                  error: (_, __) =>
                                      const Text('Added by: Unknown'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the AddCustomerScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCustomerScreen()),
          );
        },
        child: const Icon(Icons.person_add),
        tooltip: 'Add Customer',
      ),
    );
  }
}
