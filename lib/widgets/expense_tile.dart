import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../constants/app_constants.dart';
import '../../utils/format_utils.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onEdit;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(expense.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Type: ${_formatExpenseType(expense.type)}"),
            Text("Amount: ${FormatUtils.formatCurrency(expense.amount)}"),
            Text("Added by: ${expense.addedBy} at ${FormatUtils.formatTime(expense.addedAt)}"),
            if (expense.editedAt != null)
              Text("Edited by: ${expense.editedBy ?? ''} at ${FormatUtils.formatTime(expense.editedAt!)}"),
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

  String _formatExpenseType(String type) {
    switch (type) {
      case AppConstants.expenseRawMaterial:
        return "Raw Material";
      case AppConstants.expenseTransportation:
        return "Transportation";
      case AppConstants.expenseLabor:
        return "Labor";
      case AppConstants.expenseOther:
        return "Other";
      default:
        return type.capitalize();
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }
}