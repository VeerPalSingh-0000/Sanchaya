import 'package:dio/dio.dart';
void main() async {
  try {
    final dio = Dio(BaseOptions(baseUrl: 'https://graphql.anilist.co'));
    final res = await dio.post('', data: {
      'query': 'query (\$genres: [String], \$page: Int, \$perPage: Int) { Page(page: \$page, perPage: \$perPage) { pageInfo { total } media(genre_in: \$genres, type: ANIME, sort: SCORE_DESC) { id title { romaji } } } }',
      'variables': {'genres': ['Adventure'], 'page': 1, 'perPage': 20}
    });
    final media = res.data['data']['Page']['media'] as List;
    print('Anilist success: \${media.length} items');
  } catch (e) {
    print('Anilist error: \$e');
  }
}
