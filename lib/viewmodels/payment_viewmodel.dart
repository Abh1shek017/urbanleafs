import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/payment_repository.dart';
import '../models/payment_model.dart';

// Repository Provider
final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository());

// Stream of today's payments
final todaysPaymentsStreamProvider = StreamProvider.autoDispose<List<PaymentModel>>(
  (ref) {
    final repository = ref.watch(paymentRepositoryProvider);
    return repository.getTodaysPayments();
  },
);

// Future to add new payment
final addPaymentFutureProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, paymentData) async {
    final repository = ref.watch(paymentRepositoryProvider);
    await repository.addPayment(paymentData);
  },
);