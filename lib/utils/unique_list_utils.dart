// lib/utils/unique_list_utils.dart
class UniqueListUtils {
  /// Converts a dynamic JSON field to a unique string list.
  /// Handles both List and Map types safely.
  /// Falls back to provided fallback list if input is empty or null.
  static List<String> safeUniqueStringList(
    dynamic data, [
    List<String> fallback = const [],
  ]) {
    List<String> list;

    if (data is List) {
      list = data.map((e) => e.toString()).toSet().toList();
    } else if (data is Map) {
      list = data.values.map((e) => e.toString()).toSet().toList();
    } else {
      list = [];
    }

    return list.isEmpty ? fallback : list;
  }
}
