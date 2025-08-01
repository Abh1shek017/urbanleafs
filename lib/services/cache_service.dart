class CacheService {
  final Map<String, CachedItem> _cache = {};
  static const Duration defaultExpiry = Duration(minutes: 5);

  T? get<T>(String key) {
    final item = _cache[key];
    if (item == null) return null;
    
    if (DateTime.now().isAfter(item.expiryTime)) {
      _cache.remove(key);
      return null;
    }
    
    return item.data as T?;
  }

  void set<T>(String key, T data, [Duration? expiry]) {
    _cache[key] = CachedItem(
      data: data,
      expiryTime: DateTime.now().add(expiry ?? defaultExpiry),
    );
  }

  void clear() {
    _cache.clear();
  }
}

class CachedItem {
  final dynamic data;
  final DateTime expiryTime;

  CachedItem({required this.data, required this.expiryTime});
}