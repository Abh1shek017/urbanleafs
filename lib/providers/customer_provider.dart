import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/customer_repository.dart';
import '../models/customer_model.dart';

final customerRepoProvider = Provider((ref) => CustomerRepository());

final addCustomerProvider = Provider<Future<void> Function(CustomerModel)>((ref) {
  final repo = ref.watch(customerRepoProvider);
  return repo.addCustomer;
});

final updateCustomerProvider = Provider<Future<void> Function(CustomerModel)>((ref) {
  final repo = ref.watch(customerRepoProvider);
  return (CustomerModel customer) => repo.updateCustomer(customer.id, customer.toMap());
});
