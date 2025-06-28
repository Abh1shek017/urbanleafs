import 'package:intl/intl.dart';

class AppDateUtils {
  // Format date as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format time as HH:mm (24-hour format)
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Format time as hh:mm a (12-hour format with AM/PM)
  static String formatTimeAmPm(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  // Format date-time as DD/MM/YYYY HH:mm
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  // Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get today's date at midnight (00:00:00)
  static DateTime getTodayMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Get current date/time in ISO 8601 format
  static String getCurrentISODateTime() {
    return DateTime.now().toIso8601String();
  }

  // Parse ISO 8601 string to DateTime
  static DateTime parseISODateTime(String isoString) {
    return DateTime.parse(isoString);
  }

  // Check if a given date is today
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // Get the start of the day for a given date
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get the end of the day for a given date
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
