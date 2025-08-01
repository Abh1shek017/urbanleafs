import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterSection extends StatelessWidget {
  final String selectedMonth;
  final int selectedYear;
  final DateTimeRange? customRange;
  final Function(String) onMonthChanged;
  final Function(int) onYearChanged;
  final Function(DateTimeRange) onCustomRangeSelected;
  final Function(String) onQuickFilterSelected;

  const FilterSection({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    this.customRange,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onCustomRangeSelected,
    required this.onQuickFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _buildMonthDropdown()),
            const SizedBox(width: 8),
            _buildYearDropdown(),
            const SizedBox(width: 8),
            _buildCustomRangeButton(context),
            const SizedBox(width: 4),
            _buildQuickFilterMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButton<String>(
      value: selectedMonth,
      isExpanded: true,
      items: List.generate(12, (index) {
        final month = DateFormat('MMMM').format(DateTime(0, index + 1));
        return DropdownMenuItem(value: month, child: Text(month));
      }),
      onChanged: (val) {
        if (val != null) {
          final now = DateTime.now();
          final selectedMonthIndex = DateFormat('MMMM').parse(val).month;
          if (selectedYear == now.year && selectedMonthIndex > now.month) {
            return; // Your original validation logic
          }
          onMonthChanged(val);
        }
      },
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButton<int>(
      value: selectedYear,
      items: List.generate(5, (i) {
        final year = DateTime.now().year - i;
        return DropdownMenuItem(value: year, child: Text('$year'));
      }),
      onChanged: (val) {
        if (val != null) {
          onYearChanged(val);
        }
      },
    );
  }

  Widget _buildCustomRangeButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onCustomRangeSelected(picked);
        }
      },
      child: const Text('Custom Range'),
    );
  }

  Widget _buildQuickFilterMenu() {
    return PopupMenuButton<String>(
      onSelected: onQuickFilterSelected,
      icon: const Icon(Icons.filter_alt_outlined),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'this_month', child: Text('This Month')),
        const PopupMenuItem(value: 'last_month', child: Text('Last Month')),
        const PopupMenuItem(value: 'this_quarter', child: Text('This Quarter')),
        const PopupMenuItem(value: 'half_year', child: Text('Last 6 Months')),
        const PopupMenuItem(value: 'this_year', child: Text('This Year')),
        const PopupMenuItem(value: 'last_year', child: Text('Last Year')),
      ],
    );
  }
}