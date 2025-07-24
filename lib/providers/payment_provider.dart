import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Needed for DateUtils
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Add new payment under specific customer
Future<void> addPayment(
  String customerId,
  PaymentModel payment,
) async {
  final docRef = _firestore
      .collection('customers')
      .doc(customerId)
      .collection('payments')
      .doc();
    await docRef.set(payment.toJson()); // ✅ correct

}


  /// 🔹 Stream all payments for a customer
  Stream<List<PaymentModel>> getCustomerPayments(String customerId) {
    return _firestore
        .collection('customers')
        .doc(customerId)
        .collection('payments')
        .orderBy('receivedTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentModel.fromSnapshot(doc))
              .toList(),
        );
  }

  /// 🔹 Stream today’s payments for a customer
  Stream<List<PaymentModel>> getTodaysPaymentsForCustomer(String customerId) {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(Duration(days: 1));

    return _firestore
        .collection('customers')
        .doc(customerId)
        .collection('payments')
        .where(
          'receivedTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(today),
        )
        .where('receivedTime', isLessThan: Timestamp.fromDate(tomorrow))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentModel.fromSnapshot(doc))
              .toList(),
        );
  }
}
