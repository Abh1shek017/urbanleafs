class FormatUtils {
  // Format number to currency
  static String formatCurrency(double amount) {
    return "₹${amount.toStringAsFixed(2)}";
  }

  // Format date as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Format time as HH:mm
  static String formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  // Format DateTime as DD/MM/YYYY HH:mm
  static String formatDateTime(DateTime dateTime) {
    return "${formatDate(dateTime)} ${formatTime(dateTime)}";
  }

  // Format quantity with unit
  static String formatQuantity(double quantity, {String unit = "pcs"}) {
    return "$quantity $unit";
  }
}