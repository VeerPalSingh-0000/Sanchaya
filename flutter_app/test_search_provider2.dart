import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/search_provider.dart';
import 'package:flutter_app/providers/service_providers.dart';
import 'package:flutter_app/services/cache_service.dart';
import 'package:flutter/material.dart';

class MockCacheService extends CacheService {
  @override
  Future<void> init() async {}
  @override
  Map<String, dynamic>? getSearchCache(String query) => null;
  @override
  Future<void> setSearchCache(String query, Map<String, dynamic> data) async {}
}

void main() async {
  final container = ProviderContainer(
    overrides: [
      cacheServiceProvider.overrideWithValue(MockCacheService()),
    ]
  );
  
  final notifier = container.read(discoverSearchQueryProvider.notifier);
  notifier.updateQuery('#genre:12');

  await Future.delayed(Duration(seconds: 2));

  final state = container.read(discoverSearchResultsProvider);
  if (state.hasValue) {
    print('Search Provider returned: ${state.value!.results.length} items');
  } else if (state.hasError) {
    print('Search Provider Error: ${state.error}');
  } else {
    print('Search Provider Loading...');
  }
}
