import 'package:dio/dio.dart';
void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://graphql.anilist.co'));
  final res = await dio.post('', data: {
    'query': 'query (\$genres: [String], \$page: Int, \$perPage: Int) { Page(page: \$page, perPage: \$perPage) { pageInfo { total } media(genre_in: \$genres, type: ANIME, sort: SCORE_DESC) { id } } }',
    'variables': {'genres': ['Adventure'], 'page': 1, 'perPage': 20}
  });
  print(res.data['data']['Page']['pageInfo']);
}
