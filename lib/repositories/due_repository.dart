import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/due_customer_model.dart';

class DueRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<CustomerWithDue>> fetchAllCustomersWithDueData() async {
    try {
      final customersSnap = await _firestore.collection('customers').get();
      List<CustomerWithDue> result = [];

      for (final customerDoc in customersSnap.docs) {
        final data = customerDoc.data();
        final name = data['name'] ?? 'Unknown';
        final phone = data['phone'] ?? '';
        final profileUrl = data['profileUrl'] ?? '';
        final address = data['address'] ?? '';

        // Initialize sums
        double totalOrderAmount = 0;
        double totalPaymentAmount = 0;

        List<Map<String, dynamic>> allOrders = [];
        List<Map<String, dynamic>> dueOrders = [];

        // 🔹 Step 1: Fetch all orders
        final ordersSnap = await customerDoc.reference
            .collection('orders')
            .get();
        for (final doc in ordersSnap.docs) {
          final order = doc.data();

          final totalRaw = order['totalAmount'];
          final paidRaw = order['amountPaid'];
          if (totalRaw == null || paidRaw == null) continue;

          final total = (totalRaw is int)
              ? totalRaw.toDouble()
              : totalRaw as double;
          final paid = (paidRaw is int)
              ? paidRaw.toDouble()
              : paidRaw as double;
          final due = total - paid;

          totalOrderAmount += total;

          final timestamp = order['orderTime'];
          DateTime orderTime;
          if (timestamp is Timestamp) {
            orderTime = timestamp.toDate();
          } else if (timestamp is DateTime) {
            orderTime = timestamp;
          } else {
            orderTime = DateTime.now(); // fallback
          }

          final paymentStatus = order['paymentStatus'] ?? 'Unpaid';

          final orderData = {
            'totalAmount': total,
            'amountPaid': paid,
            'dueAmount': due,
            'orderTime': orderTime,
            'paymentStatus': paymentStatus,
          };

          allOrders.add(orderData);

          if (due > 0) {
            dueOrders.add(orderData);
          }
        }

        // 🔹 Step 2: Fetch all payments
        final paymentsSnap = await customerDoc.reference
            .collection('payments')
            .get();
        for (final paymentDoc in paymentsSnap.docs) {
          final payment = paymentDoc.data();
          final amountRaw = payment['amount'];
          if (amountRaw == null) continue;

          final amount = (amountRaw is int)
              ? amountRaw.toDouble()
              : amountRaw as double;
          totalPaymentAmount += amount;
        }
        final payments = paymentsSnap.docs.map((p) => p.data()).toList();

        // 🔹 Step 3: Calculate total due
        final totalDue = totalOrderAmount - totalPaymentAmount;

        // 🔹 Step 4: Add to result
        final shopName = data['shopName'] ?? ''; // or null if you prefer

        result.add(
          CustomerWithDue(
            name: name,
            phone: phone,
            profileImageUrl: profileUrl,
            shopName: shopName, // <-- add this line
            address: address,
            totalDue: totalDue,
            dueOrders: dueOrders,
            allOrders: allOrders,
            payments: payments,
          ),
        );
      }

      // Sort descending by due
      result.sort((a, b) => b.totalDue.compareTo(a.totalDue));
      return result;
    } catch (e) {
      print('Error fetching customers with due data: $e');
      return [];
    }
  }
}
