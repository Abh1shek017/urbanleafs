import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/balance_sheet_state.dart';
import '../services/balance_sheet_service.dart';
import '../repositories/balance_sheet_repository.dart';
import '../services/cache_service.dart';
import '../providers/due_provider.dart';
import '../../viewmodels/balance_sheet_viewmodel.dart';

// Create providers for our services
final cacheServiceProvider = Provider((ref) => CacheService());
final balanceSheetRepositoryProvider = Provider(
  (ref) => BalanceSheetRepository(),
);
final balanceSheetServiceProvider = Provider((ref) {
  final repository = ref.watch(balanceSheetRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  return BalanceSheetService(repository, cache);
});
final balanceSheetViewModelProvider =
    StateNotifierProvider<BalanceSheetViewModel, BalanceSheetState>(
      (ref) => BalanceSheetViewModel(ref),
    );

final balanceSheetProvider =
    StateNotifierProvider<BalanceSheetNotifier, BalanceSheetState>((ref) {
      final service = ref.watch(balanceSheetServiceProvider);
      return BalanceSheetNotifier(service, ref);
    });

class BalanceSheetNotifier extends StateNotifier<BalanceSheetState> {
  final BalanceSheetService _service;
  final Ref _ref;

  BalanceSheetNotifier(this._service, this._ref) : super(BalanceSheetState());

  Future<void> loadData({DateTimeRange? range}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('=== Loading Balance Sheet Data ===');
      print('Range: ${range ?? _getDefaultRange()}');

      // Debug database structure first
      await _service.debugDatabaseStructure();

      // Get transactions from service
      final transactions = await _service.getTransactions(
        range ?? _getDefaultRange(),
      );
      print('Fetched ${transactions.length} transactions');

      // Get due amounts from existing provider
      final dueData = _ref.read(allCustomersWithDueProvider);
      double totalDue = 0.0;
      int dueCustomerCount = 0;

      dueData.whenData((customers) {
        totalDue = customers.fold(0.0, (sum, c) => sum + c.totalDue);
        dueCustomerCount = customers.length;
        print('Due amounts: $totalDue from $dueCustomerCount customers');
      });

      // Calculate summary
      final summary = await _service.calculateSummary(
        transactions,
        totalDue,
        dueCustomerCount,
      );
      print(
        'Summary calculated: Expenses=${summary.totalExpenses}, Raw=${summary.rawPurchases}',
      );

      state = state.copyWith(
        isLoading: false,
        transactions: transactions,
        summary: summary,
        selectedRange: range,
      );
    } catch (e) {
      print('Error loading balance sheet data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  DateTimeRange _getDefaultRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  Future<void> refreshData() async {
    _service.clearCache();
    await loadData(range: state.selectedRange);
  }
}
