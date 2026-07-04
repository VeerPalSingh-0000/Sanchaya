import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _trendingBox = 'trending_cache';
  static const String _mediaDetailsBox = 'media_details_cache';
  static const String _searchBox = 'search_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_trendingBox);
    await Hive.openBox(_mediaDetailsBox);
    await Hive.openBox(_searchBox);
  }

  // Generic Cache Wrapper
  Map<String, dynamic>? _getCache(String boxName, String key, Duration ttl) {
    final box = Hive.box(boxName);
    final data = box.get(key) as Map<dynamic, dynamic>?;
    
    if (data == null) return null;

    final timestamp = data['timestamp'] as int;
    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    if (DateTime.now().difference(cachedTime) > ttl) {
      box.delete(key);
      return null;
    }

    // Use jsonDecode/jsonEncode to recursively convert Map<dynamic, dynamic> to Map<String, dynamic>
    final payload = data['payload'];
    return jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
  }

  Future<void> _setCache(String boxName, String key, Map<String, dynamic> payload) async {
    final box = Hive.box(boxName);
    await box.put(key, {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    });
  }

  // Specific Methods
  Map<String, dynamic>? getTrendingCache(String key) {
    return _getCache(_trendingBox, key, const Duration(hours: 1));
  }

  Future<void> setTrendingCache(String key, Map<String, dynamic> data) async {
    await _setCache(_trendingBox, key, data);
  }

  Map<String, dynamic>? getMediaDetailsCache(String id) {
    return _getCache(_mediaDetailsBox, id, const Duration(hours: 24));
  }

  Future<void> setMediaDetailsCache(String id, Map<String, dynamic> data) async {
    await _setCache(_mediaDetailsBox, id, data);
  }

  Map<String, dynamic>? getSearchCache(String query) {
    return _getCache(_searchBox, query, const Duration(minutes: 30));
  }

  Future<void> setSearchCache(String query, Map<String, dynamic> data) async {
    await _setCache(_searchBox, query, data);
  }

  Future<void> clearAll() async {
    await Hive.box(_trendingBox).clear();
    await Hive.box(_mediaDetailsBox).clear();
    await Hive.box(_searchBox).clear();
  }
}
