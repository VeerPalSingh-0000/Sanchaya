import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/services/anilist_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final anilistService = container.read(anilistServiceProvider);

  try {
    print('Fetching episodes for One Piece (MAL ID 21)...');
    final start = DateTime.now();
    final episodes = await anilistService.getAnimeEpisodes(21);
    final end = DateTime.now();
    print('Fetched ${episodes.length} episodes in ${end.difference(start).inSeconds}s');
    
    if (episodes.isNotEmpty) {
      print('First episode arc: ${episodes.first.arcName}');
      print('Last episode arc: ${episodes.last.arcName}');
      
      final arcs = episodes.map((e) => e.arcName).toSet();
      print('Total unique arcs found: ${arcs.length}');
    }
  } catch (e, stack) {
    print('Error: $e\n$stack');
  }
}
