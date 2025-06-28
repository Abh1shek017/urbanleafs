import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/payment_repository.dart';
import '../models/payment_model.dart';

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository());

// Stream provider for today's payments
final todaysPaymentsStreamProvider = StreamProvider.autoDispose<List<PaymentModel>>(
  (ref) {
    final repository = ref.watch(paymentRepositoryProvider);
    return repository.getTodaysPayments();
  },
);