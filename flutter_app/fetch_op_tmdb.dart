import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  final _dio = Dio();
  final tmdbKey = 'd60e665c617655185db02ee381c7bd0a';
  
  try {
    print('Fetching One Piece (TMDB ID 37854)...');
    final response = await _dio.get(
      'https://api.themoviedb.org/3/tv/37854?api_key=$tmdbKey',
    );
    
    final seasons = response.data['seasons'] as List<dynamic>;
    int totalEpisodes = 0;
    List<Map<String, dynamic>> allEpisodes = [];
    
    for (var season in seasons) {
      final seasonNumber = season['season_number'];
      if (seasonNumber == 0) continue; // Skip specials
      
      print('Fetching season $seasonNumber...');
      final sResponse = await _dio.get(
        'https://api.themoviedb.org/3/tv/37854/season/$seasonNumber?api_key=$tmdbKey',
      );
      
      final eps = sResponse.data['episodes'] as List<dynamic>;
      for (var ep in eps) {
        totalEpisodes++;
        allEpisodes.add({
          'mal_id': totalEpisodes,
          'title': ep['name'],
          'title_japanese': '',
          'aired': ep['air_date'] != null ? ep['air_date'] + "T00:00:00+00:00" : null,
          'filler': false,
          'recap': false,
          'synopsis': ep['overview'],
        });
      }
    }
    
    print('Total absolute episodes fetched: $totalEpisodes');
    File('assets/data/one_piece_episodes.json').writeAsStringSync(json.encode(allEpisodes));
    print('Saved to assets/data/one_piece_episodes.json');
    
  } catch (e) {
    print('Error: $e');
  }
}
