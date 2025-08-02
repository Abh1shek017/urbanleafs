import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_entry_model.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionEntry> transactions;
  final Function(BuildContext, TransactionEntry) onTransactionTap;
  final ScrollController? scrollController;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.onTransactionTap,
    this.scrollController,
  });

  // static final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const EmptyTransactionState();
    }

    return ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return TransactionCard(
          transaction: tx,
          onTap: () => onTransactionTap(context, tx),
        );
      },
    );
  }
}

class TransactionCard extends StatelessWidget {
  final TransactionEntry transaction;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final bgColor = isExpense
        ? const Color.fromARGB(255, 176, 57, 10) // Reddish for expenses
        : const Color.fromARGB(255, 78, 184, 81); // Greenish for sales

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransactionHeader(),
            const SizedBox(height: 4),
            _buildAmountRow(),
            const SizedBox(height: 4),
            _buildTransactionDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHeader() {
    final title = transaction.type == 'sold'
        ? 'Customer: ${transaction.description}'
        : 'Expense: ${transaction.description}';

    return Row(
      children: [
        Icon(
          transaction.type == 'sold' ? Icons.sell : Icons.payment,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildTransactionBadge(),
      ],
    );
  }

  Widget _buildAmountRow() {
    return Row(
      children: [
        const Icon(
          Icons.currency_rupee,
          color: Colors.white,
          size: 18,
        ),
        Text(
          transaction.amount.toStringAsFixed(2),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (transaction.type == 'sold' && transaction.itemType != null)
          _buildDetailRow(
            Icons.inventory,
            'Item Type: ${transaction.itemType}',
          ),
        _buildDetailRow(
          Icons.access_time,
          'Date: ${_dateFormat.format(transaction.addedAt)}',
        ),
        _buildDetailRow(
          Icons.category,
          'Type: ${transaction.type.toUpperCase()}',
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        transaction.type.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class EmptyTransactionState extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final VoidCallback? onRefresh;

  const EmptyTransactionState({
    super.key,
    this.message,
    this.icon,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'No transactions found for this period.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or date range.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}