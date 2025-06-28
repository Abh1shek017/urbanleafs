import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome to UrbanLeafs",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildQuickStats(context, 'Today’s Orders', '25 orders'),
          _buildQuickStats(context, 'Attendance (Morning)', '8/10 P'),
          _buildQuickStats(context, 'Attendance (Afternoon)', '6/10 P'),
          _buildQuickStats(context, 'Inventory Status', 'Plates: 12,000 pcs'),
          _buildQuickStats(context, 'Balance Sheet', '₹3,200 collected today'),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, String title, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}