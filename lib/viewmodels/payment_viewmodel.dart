import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/payment_repository.dart';
import '../models/payment_model.dart';

/// 🔹 Specific customer's repository (you can keep this for other uses)
final paymentRepositoryProvider = Provider.family<PaymentRepository, String>(
  (ref, customerId) => PaymentRepository(),
);

/// 🔹 Today's payments for a specific customer (you can keep this too)
final todaysPaymentsStreamProvider = StreamProvider.family
    .autoDispose<List<PaymentModel>, String>((ref, customerId) {
  final repository = ref.watch(paymentRepositoryProvider(customerId));
  return repository.getTodaysPayments(customerId);
});

/// 🔹 Add a new payment for a customer
final addPaymentProvider = Provider.family<void Function(), PaymentModel>((ref, payment) {
  return () async {
    final repo = ref.read(paymentRepositoryProvider(payment.customerId));
    await repo.addPayment(payment.customerId, payment);
  };
});



/// 🔹 NEW: All today's payments across all customers
final allTodaysPaymentsProvider =
    StreamProvider.autoDispose<List<PaymentModel>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return firestore
      .collectionGroup('payments') // ✅ searches all payments subcollections
      .where('receivedTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('receivedTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
      .orderBy('receivedTime', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList());
});
