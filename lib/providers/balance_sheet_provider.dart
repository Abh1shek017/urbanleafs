import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/balance_sheet_viewmodel.dart';
import '../models/balance_sheet_state.dart';
import 'order_provider.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

final balanceSheetViewModelProvider =
    StateNotifierProvider<BalanceSheetViewModel, BalanceSheetState>((ref) {
      return BalanceSheetViewModel();
    });

final balanceSheetProvider =
    StateNotifierProvider<BalanceSheetNotifier, BalanceSheetState>(
      (ref) => BalanceSheetNotifier(ref.read(orderRepositoryProvider)),
    );

class BalanceSheetNotifier extends StateNotifier<BalanceSheetState> {
  final OrderRepository orderRepo;

  BalanceSheetNotifier(this.orderRepo) : super(BalanceSheetState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      state = state.copyWith(isLoading: true);

      // Fetch all orders
      final snapshot = await orderRepo.collection.get();
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      double totalSold = 0;

      for (var order in orders) {
        totalSold += order.totalAmount;
      }

      state = state.copyWith(isLoading: false, totalSold: totalSold);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
