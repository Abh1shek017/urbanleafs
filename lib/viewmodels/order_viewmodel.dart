import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/order_repository.dart';
import '../models/order_model.dart';

// Repository Provider
final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository());

// Stream of today's orders
final todaysOrdersStreamProvider = StreamProvider.autoDispose<List<OrderModel>>(
  (ref) {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getTodaysOrders();
  },
);
final todaysOrderCountStreamProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.countTodaysOrders();
});

// Future to add new order
final addOrderFutureProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, orderData) async {
    final repository = ref.watch(orderRepositoryProvider);
    await repository.addOrder(orderData);
  },
);