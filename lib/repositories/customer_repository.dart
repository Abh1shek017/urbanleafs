import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
class CustomerRepository {
  final _collection = FirebaseFirestore.instance.collection('customers');

  Future<void> addCustomer(CustomerModel customer) async {
    await _collection.doc(customer.id).set(customer.toMap());
  } 

  Future<List<CustomerModel>> getAllCustomers() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }
  

  Future<void> deleteCustomer(String id) async {
    await _collection.doc(id).delete();
  }
}
