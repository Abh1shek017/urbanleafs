import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/expense_repository.dart';
import '../models/expense_model.dart';

final expenseRepositoryProvider =
    Provider<ExpenseRepository>((ref) => ExpenseRepository());

// Stream of today's expenses
final todaysExpensesStreamProvider = StreamProvider.autoDispose<List<ExpenseModel>>(
  (ref) {
    final repository = ref.watch(expenseRepositoryProvider);
    return repository.getTodaysExpenses();
  },
);

// Future to add new expense
final markExpenseFutureProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, expenseData) async {
    final repository = ref.watch(expenseRepositoryProvider);
    await repository.addExpense(expenseData);
  },
);

// Future to update existing expense
final updateExpenseFutureProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, args) async {
    final repository = ref.watch(expenseRepositoryProvider);
    final String expenseId = args['id'] as String;
    final Map<String, dynamic> updateData = args['data'] as Map<String, dynamic>;
    await repository.updateExpense(expenseId, updateData);
  },
);