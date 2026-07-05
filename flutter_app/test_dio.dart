import 'package:dio/dio.dart';

void main() async {
  final _dio = Dio();
  _dio.options.baseUrl = 'https://graphql.anilist.co';

  final query = '''
    query GetAnimeDetails(\$id: Int!) { Media(id: \$id, type: ANIME) { id, idMal } }
  ''';

  try {
    final response = await _dio.post(
      '',
      data: {'query': query, 'variables': {'id': 21}},
      options: Options(headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}),
    );
    print('Result: \${response.data}');
  } catch (e) {
    print('Error: \$e');
  }
}
