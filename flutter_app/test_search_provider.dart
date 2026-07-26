import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/search_provider.dart';
import 'package:flutter_app/models/search_result.dart';
import 'package:flutter_app/providers/service_providers.dart';
import 'package:flutter_app/services/cache_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cacheService = CacheService();
  await cacheService.init();
  final container = ProviderContainer(
    overrides: [
      cacheServiceProvider.overrideWithValue(cacheService),
    ]
  );
  
  final notifier = container.read(discoverSearchQueryProvider.notifier);
  notifier.updateQuery('#genre:12');

  // Let debounce timer run
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
