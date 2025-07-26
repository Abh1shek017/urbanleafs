import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import 'package:rxdart/rxdart.dart';

class CustomerRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('customers');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<void> addCustomer(CustomerModel customer) async {
    await _collection.doc(customer.id).set(customer.toMap());
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
