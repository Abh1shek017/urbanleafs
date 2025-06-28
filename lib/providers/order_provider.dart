import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/order_repository.dart';
import '../models/order_model.dart';

final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository());

// Stream provider for today's orders
final todaysOrdersStreamProvider = StreamProvider.autoDispose<List<OrderModel>>(
  (ref) {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getTodaysOrders();
  },
);