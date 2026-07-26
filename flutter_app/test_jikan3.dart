import 'package:dio/dio.dart';

void main() async {
  final _dio = Dio();
  _dio.options.headers = {
    'User-Agent': 'curl/8.5.0',
    'Accept': '*/*'
  };
  try {
    final response = await _dio.get('https://api.jikan.moe/v4/anime/21/episodes?page=1');
    print('Success: ${response.data['data']?.length} episodes');
  } catch (e) {
    if (e is DioException) {
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
    }
  }
}
