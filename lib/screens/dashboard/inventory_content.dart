import 'package:flutter/material.dart';

class InventoryContent extends StatelessWidget {
  const InventoryContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Inventory Status",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildInventoryCard(context, 'Paper Rolls', '500 kg'),
          _buildInventoryCard(context, 'Plates', '12,000 pcs'),
          _buildInventoryCard(context, 'Packaging Boxes', '200 units'),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, String itemName, String quantity) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(itemName),
        subtitle: Text("Available Stock"),
        trailing: Chip(
          label: Text(quantity),
          // ignore: deprecated_member_use
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
    );
  }
}