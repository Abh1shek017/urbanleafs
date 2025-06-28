import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Needed for DateUtils
import '../models/payment_model.dart';
import 'base_repository.dart';

class PaymentRepository extends BaseRepository {
  PaymentRepository()
    : super(FirebaseFirestore.instance.collection('payments'));

  /// Stream of today's payments (real-time)
  Stream<List<PaymentModel>> getTodaysPayments() {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(Duration(days: 1));

    return collection
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

  /// Stream of total earnings today (real-time)
  Stream<double> totalTodaysEarnings() {
    return getTodaysPayments().map(
      (payments) =>
          payments.fold(0.0, (total, payment) => total + payment.amount),
    );
  }

  /// Add new payment
  Future<void> addPayment(Map<String, dynamic> paymentData) async {
    await collection.add(paymentData);
  }
}
