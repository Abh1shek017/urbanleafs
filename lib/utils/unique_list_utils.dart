// lib/utils/unique_list_utils.dart
class UniqueListUtils {
  /// Converts a dynamic JSON field to a unique string list.
  /// Handles List and Map types safely, guarantees a fresh mutable List<String>.
  /// Falls back to provided fallback list if input is empty or null.
  static List<String> safeUniqueStringList(
    dynamic data, [
    List<String> fallback = const [],
  ]) {
    final Set<String> uniqueSet = {};

    if (data is List) {
      uniqueSet.addAll(data.map((e) => e.toString()));
    } else if (data is Map) {
      uniqueSet.addAll(data.values.map((e) => e.toString()));
    }

    if (uniqueSet.isEmpty) {
      uniqueSet.addAll(fallback);
    }

    // ✅ Always return a fresh modifiable list
    return List<String>.from(uniqueSet);
  }
}
