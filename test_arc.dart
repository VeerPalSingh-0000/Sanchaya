import 'dart:convert';
import 'dart:io';
void main() {
  final str = File('flutter_app/assets/data/arc_data.json').readAsStringSync();
  final List<dynamic> arcDataJson = json.decode(str);
  final animeArcJson = arcDataJson.firstWhere(
    (a) => a['anime_id'] == 21,
    orElse: () => null,
  );
  print('Result: ${animeArcJson?['anime_id']}');
}
