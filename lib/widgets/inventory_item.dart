import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../utils/format_utils.dart';

class InventoryItem extends StatelessWidget {
  final InventoryModel item;
  final VoidCallback? onEdit;

  const InventoryItem({
    super.key,
    required this.item,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(item.itemName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Quantity: ${item.quantity} ${item.unit}"),
            Text("Last Updated: ${FormatUtils.formatDateTime(item.lastUpdated)} by ${item.updatedBy}"),
          ],
        ),
        trailing: onEdit != null
            ? IconButton(
                icon: Icon(Icons.edit),
                onPressed: onEdit,
              )
            : null,
      ),
    );
  }
}