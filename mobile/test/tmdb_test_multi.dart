import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/tmdb_service.dart';

void main() {
  test('search multi', () async {
    final service = TmdbService();
    
    var res1 = await service.searchMulti('pritam');
    print('multi pritam: ${res1.results.length}');
    
    var res2 = await service.searchMulti('Pritam');
    print('multi Pritam: ${res2.results.length}');
  });
}
