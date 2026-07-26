import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    final arcDataString = File('assets/data/arc_data.json').readAsStringSync();
    final arcDataJson = json.decode(arcDataString) as List<dynamic>;
    
    final idMal = 21;
    final animeArcJson = arcDataJson.firstWhere(
      (a) => a['anime_id'] == idMal,
      orElse: () => null,
    );
    
    if (animeArcJson == null) {
      print('Not found in arc_data.json');
      return;
    }
    
    final arcs = animeArcJson['arcs'] as List<dynamic>?;
    print('Found ${arcs?.length} arcs for One Piece');
    print('First arc: ${arcs?[0]}');
    
  } catch (e, stack) {
    print('Error: $e\n$stack');
  }
}
