import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/tmdb_service.dart';

void main() {
  test('fetch tmdb', () async {
    final service = TmdbService();
    try {
      final search = await service.searchTV('pritam and');
      print('Search results: ${search.results.length}');
      for (var m in search.results) {
        print('Found: ${m.title} (ID: ${m.id})');
        try {
          final details = await service.getTVDetails(m.id);
          print('Details fetched successfully for ${m.title}');
        } catch (e) {
          print('Error fetching details for ${m.title}: $e');
        }
      }
    } catch (e, st) {
      print('Error: $e\n$st');
    }
  });
}
