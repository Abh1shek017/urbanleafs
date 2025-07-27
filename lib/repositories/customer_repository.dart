import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import 'package:rxdart/rxdart.dart';

class CustomerRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('customers');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<void> addCustomer(CustomerModel customer) async {
    await _collection.doc(customer.id).set(customer.toMap());
  }
  Future<double> getTotalSoldAcrossAllCustomers() async {
  final firestore = FirebaseFirestore.instance;
  double totalSold = 0;

  final customerSnapshots = await firestore.collection('customers').get();

  for (var customerDoc in customerSnapshots.docs) {
    final ordersSnapshot = await firestore
        .collection('customers')
        .doc(customerDoc.id)
        .collection('orders')
        .get();

    for (var orderDoc in ordersSnapshot.docs) {
      final orderData = orderDoc.data();
      final orderTotal = orderData['totalAmount'] ?? 0;
      totalSold += (orderTotal is int || orderTotal is double) ? orderTotal.toDouble() : 0.0;
    }
  }

  return totalSold;
}

  Future<List<CustomerModel>> getAllCustomers() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }
  Future<(double totalDue, int count)> calculateDueAmounts() async {
  final customerSnap = await _firestore.collection('customers').get();
  double totalDue = 0;
  int dueCustomerCount = 0;

  for (final doc in customerSnap.docs) {
    final customerId = doc.id;

    // Fetch all orders
    final orderSnap = await _firestore
        .collection('customers')
        .doc(customerId)
        .collection('orders')
        .get();
    double totalOrder = 0;
    for (final order in orderSnap.docs) {
      final data = order.data();
      totalOrder += (data['totalAmount'] as num?)?.toDouble() ?? 0;
    }

    // Fetch all payments
    final paymentSnap = await _firestore
        .collection('customers')
        .doc(customerId)
        .collection('payments')
        .get();
    double totalPaid = 0;
    for (final payment in paymentSnap.docs) {
      final data = payment.data();
      totalPaid += (data['amount'] as num?)?.toDouble() ?? 0;
    }

    final due = totalOrder - totalPaid;
    if (due > 0) {
      totalDue += due;
      dueCustomerCount++;
    }
  }

  return (totalDue, dueCustomerCount);
}

Stream<double> watchDueAmount(String customerId) {
  final ordersStream = _firestore
      .collection('customers')
      .doc(customerId)
      .collection('orders')
      .snapshots();

  final paymentsStream = _firestore
      .collection('customers')
      .doc(customerId)
      .collection('payments')
      .snapshots();

  return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, double>(
    ordersStream,
    paymentsStream,
    (orderSnap, paymentSnap) {
      double totalOrder = 0;
      double totalPaid = 0;

      for (var doc in orderSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalOrder += (data['totalAmount'] as num?)?.toDouble() ?? 0;
      }

      for (var doc in paymentSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalPaid += (data['amount'] as num?)?.toDouble() ?? 0;
      }

      return totalOrder - totalPaid;
    },
  );
}

  Future<void> deleteCustomer(String id) async {
    await _collection.doc(id).delete();
  }
}
