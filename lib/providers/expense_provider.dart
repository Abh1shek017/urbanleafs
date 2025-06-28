import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/expense_repository.dart';
import '../models/expense_model.dart';

final expenseRepositoryProvider =
    Provider<ExpenseRepository>((ref) => ExpenseRepository());

// Stream provider for today's expenses only (used in Balance Sheet Screen)
final todaysExpensesStreamProvider = StreamProvider.autoDispose<List<ExpenseModel>>(
  (ref) {
    final repository = ref.watch(expenseRepositoryProvider);
    return repository.getTodaysExpenses();
  },
);

// Stream provider for all expenses (admin use)
final allExpensesStreamProvider = StreamProvider.autoDispose<List<ExpenseModel>>(
  (ref) {
    final repository = ref.watch(expenseRepositoryProvider);
    return repository.getAllExpenses();
  },
);