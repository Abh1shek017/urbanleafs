extension StringCasingExtension on String {
  String capitalize() {
    if (trim().isEmpty) return '';
    final str = trim().toLowerCase();
    return str[0].toUpperCase() + str.substring(1);
  }
}
