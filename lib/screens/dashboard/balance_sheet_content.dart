import 'package:flutter/material.dart';

class BalanceSheetContent extends StatelessWidget {
  const BalanceSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Balance Sheet Summary",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildBalanceCard(context, 'Total Expenses', '₹25,400'),
          _buildBalanceCard(context, 'Total Income', '₹42,000'),
          _buildBalanceCard(context, 'Net Profit', '₹16,600'),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, String title, String value) {
    return Card(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}