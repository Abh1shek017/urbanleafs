import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/balance_sheet_viewmodel.dart';
import '../models/balance_sheet_state.dart';

final balanceSheetViewModelProvider =
    StateNotifierProvider<BalanceSheetViewModel, BalanceSheetState>((ref) {
  return BalanceSheetViewModel();
});
