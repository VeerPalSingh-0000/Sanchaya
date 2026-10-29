import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/tmdb_service.dart';

void main() {
  test('search tv', () async {
    final service = TmdbService();
    
    var res1 = await service.searchTV('pritam');
    print('pritam: ${res1.results.length}');
    
    var res2 = await service.searchTV('Pritam');
    print('Pritam: ${res2.results.length}');
    
    var res3 = await service.searchTV('pritam and');
    print('pritam and: ${res3.results.length}');
    
    var res4 = await service.searchTV('pritam and pedro');
    print('pritam and pedro: ${res4.results.length}');
    
    var res5 = await service.searchTV('Pritam and Pedro');
    print('Pritam and Pedro: ${res5.results.length}');
  });
}
