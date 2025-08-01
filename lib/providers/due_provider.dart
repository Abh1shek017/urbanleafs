import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/due_repository.dart';
import '../models/due_customer_model.dart';

final dueRepositoryProvider = Provider<DueRepository>((ref) {
  return DueRepository();
});



final allCustomersWithDueProvider = FutureProvider<List<CustomerWithDue>>((ref) async {
  final repo = ref.read(dueRepositoryProvider);
  return await repo.fetchAllCustomersWithDueData(); // ✅ match the method name
});
