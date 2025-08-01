import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/balance_sheet_state.dart';
import '../../providers/due_provider.dart';
import '../../repositories/customer_repository.dart';

class SummaryGrid extends ConsumerWidget {
  final BalanceSheetState state;
  final double cardScale;
  final VoidCallback onTotalSoldTap;
  final VoidCallback onTotalExpensesTap;
  final VoidCallback onRawPurchasesTap;
  final VoidCallback onDueAmountsTap;

  const SummaryGrid({
    super.key,
    required this.state,
    required this.cardScale,
    required this.onTotalSoldTap,
    required this.onTotalExpensesTap,
    required this.onRawPurchasesTap,
    required this.onDueAmountsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Transform(
      transform: Matrix4.identity()..scale(1.0, cardScale),
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildTotalSoldCard(),
                _buildTotalExpensesCard(),
                _buildRawPurchasesCard(),
              ],
            ),
            const SizedBox(height: 8),
            _buildDueAmountsCard(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSoldCard() {
    return FutureBuilder<double>(
      future: _calculateTotalSold(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSummaryCard(
            'Total Sold',
            'Loading...',
            Colors.green[300]!,
            onTotalSoldTap,
          );
        } else if (snapshot.hasError) {
          return _buildSummaryCard(
            'Total Sold',
            'Error',
            Colors.green[300]!,
            onTotalSoldTap,
          );
        } else {
          final total = snapshot.data ?? 0.0;
          return _buildSummaryCard(
            'Total Sold',
            '₹${total.toStringAsFixed(2)}',
            Colors.green[300]!,
            onTotalSoldTap,
          );
        }
      },
    );
  }

  Widget _buildTotalExpensesCard() {
    return _buildSummaryCard(
      'Total Expenses',
      '₹${state.totalExpenses.toStringAsFixed(2)}',
      Colors.red[300]!,
      onTotalExpensesTap,
    );
  }

  Widget _buildRawPurchasesCard() {
    return _buildSummaryCard(
      'Raw Purchases',
      '₹${state.rawPurchases.toStringAsFixed(2)}',
      Colors.grey[400]!,
      onRawPurchasesTap,
    );
  }

  Widget _buildDueAmountsCard(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, _) {
        final dueAsync = ref.watch(allCustomersWithDueProvider);

        return dueAsync.when(
          loading: () => _buildSummaryCard(
            'Due Amounts',
            'Loading…',
            Colors.orange[400]!,
            onDueAmountsTap,
          ),
          error: (e, _) => _buildSummaryCard(
            'Due Amounts',
            'Error',
            Colors.orange[400]!,
            onDueAmountsTap,
          ),
          data: (customers) {
            final totalDue = customers.fold<double>(
              0,
              (sum, c) => sum + c.totalDue,
            );
            final count = customers.length;

            return _buildSummaryCard(
              'Due Amounts',
              '₹${totalDue.toStringAsFixed(2)} from $count Customers',
              Colors.orange[400]!,
              onDueAmountsTap,
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(amount, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<double> _calculateTotalSold() async {
    final repo = CustomerRepository();
    return await repo.getTotalSoldAcrossAllCustomers();
  }
}