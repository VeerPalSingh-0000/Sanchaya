import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/anilist_service.dart';

void main() {
  test('search anime', () async {
    final service = AnilistService();
    
    var res1 = await service.searchAnime('pritam', 1, 10);
    print('pritam: ${res1.results.length}');
    
    var res2 = await service.searchAnime('Pritam', 1, 10);
    print('Pritam: ${res2.results.length}');
    
    var res3 = await service.searchAnime('pritam and pedro', 1, 10);
    print('pritam and pedro: ${res3.results.length}');
  });
}
