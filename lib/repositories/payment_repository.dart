import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of today's payments for a customer
  Stream<List<PaymentModel>> getTodaysPayments(String customerId) {
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

  /// Stream of total earnings today for a customer
  Stream<double> totalTodaysEarnings(String customerId) {
    return getTodaysPayments(customerId).map(
      (payments) =>
          payments.fold(0.0, (total, payment) => total + payment.amount),
    );
  }
  String _twoDigits(int n) => n.toString().padLeft(2, '0');


  /// Add new payment
Future<void> addPayment(String customerId, PaymentModel payment) async {
  final now = DateTime.now();
final formattedDate = '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
final paymentId = '${payment.amount.toStringAsFixed(0)}_payment_$formattedDate';


  final docRef = _firestore
      .collection('customers')
      .doc(customerId)
      .collection('payments')
      .doc(paymentId);

  await docRef.set(
    payment.copyWith(id: paymentId).toJson(),
  );
}
}
