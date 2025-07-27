import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/due_customer_model.dart';

class DueRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CustomerWithDue>> fetchCustomersWithDueOrders() async {
    final customersSnap = await _firestore.collection('customers').get();
    List<CustomerWithDue> result = [];

    for (final customerDoc in customersSnap.docs) {
      final data = customerDoc.data();
      final name          = data['name']           ?? 'Unknown';
      final phone         = data['phone']          ?? '';
      final profileUrl    = data['profileUrl']     ?? '';
      final address       = data['address']        ?? '';

      final ordersSnap    = await customerDoc.reference.collection('orders').get();
      double totalDue     = 0;

      // NEW: collect all orders
      List<Map<String, dynamic>> allOrders = [];
      List<Map<String, dynamic>> dueOrders = [];

      for (final doc in ordersSnap.docs) {
        final order = doc.data();

        // Safely parse amounts
        final totalRaw = order['totalAmount'];
        final paidRaw  = order['amountPaid'];
        if (totalRaw == null || paidRaw == null) continue;

        final total = (totalRaw is int) ? totalRaw.toDouble() : totalRaw as double;
        final paid  = (paidRaw  is int) ? paidRaw .toDouble() : paidRaw  as double;
        final due   = total - paid;

        // Parse timestamp
        final timestamp = order['orderTime'];
        final orderTime = (timestamp is Timestamp)
            ? timestamp.toDate()
            : DateTime.now();

        // Add to allOrders
        allOrders.add({
          'totalAmount': total,
          'amountPaid':  paid,
          'dueAmount':   due,
          'orderTime':   orderTime,
          // copy any other needed fields here...
        });

        // If there's a due > 0, also add to dueOrders
        if (due > 0) {
          dueOrders.add({
            'totalAmount': total,
            'amountPaid':  paid,
            'dueAmount':   due,
            'orderTime':   orderTime,
          });
          totalDue += due;
        }
      }

      // Only include customers who owe something
      if (totalDue > 0) {
        result.add(CustomerWithDue(
          name:           name,
          phone:          phone,
          profileImageUrl:profileUrl,
          address:        address,
          totalDue:       totalDue,
          dueOrders:      dueOrders,
          allOrders:      allOrders,   // NEW FIELD
        ));
      }
    }

    return result;
  }
  Future<List<CustomerWithDue>> fetchAllCustomersWithDueData() async {
  final customersSnap = await _firestore.collection('customers').get();
  List<CustomerWithDue> result = [];

  for (final customerDoc in customersSnap.docs) {
    final data = customerDoc.data();
    final name          = data['name']           ?? 'Unknown';
    final phone         = data['phone']          ?? '';
    final profileUrl    = data['profileUrl']     ?? '';
    final address       = data['address']        ?? '';

    final ordersSnap    = await customerDoc.reference.collection('orders').get();
    double totalDue     = 0;

    List<Map<String, dynamic>> allOrders = [];
    List<Map<String, dynamic>> dueOrders = [];

    for (final doc in ordersSnap.docs) {
      final order = doc.data();

      final totalRaw = order['totalAmount'];
      final paidRaw  = order['amountPaid'];
      if (totalRaw == null || paidRaw == null) continue;

      final total = (totalRaw is int) ? totalRaw.toDouble() : totalRaw as double;
      final paid  = (paidRaw  is int) ? paidRaw .toDouble() : paidRaw  as double;
      final due   = total - paid;

      final timestamp = order['orderTime'];
      final orderTime = (timestamp is Timestamp)
          ? timestamp.toDate()
          : DateTime.now();

      final orderData = {
        'totalAmount': total,
        'amountPaid':  paid,
        'dueAmount':   due,
        'orderTime':   orderTime,
      };

      allOrders.add(orderData);

      if (due > 0) {
        dueOrders.add(orderData);
        totalDue += due;
      }
    }

    result.add(CustomerWithDue(
      name:            name,
      phone:           phone,
      profileImageUrl: profileUrl,
      address:         address,
      totalDue:        totalDue,
      dueOrders:       dueOrders,
      allOrders:       allOrders,
    ));
  }

  // ✅ Sort customers by due descending
  result.sort((a, b) => b.totalDue.compareTo(a.totalDue));

  return result;
}

}
