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

// ✅ New: Stream provider for all orders (used in balance sheet)
final allOrdersProvider = StreamProvider<List<OrderModel>>(
  (ref) {
    final repository = ref.watch(orderRepositoryProvider);
    return repository.getAllOrders(); // You must define this in the repo
  },
);
