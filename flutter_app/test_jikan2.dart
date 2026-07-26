import 'package:dio/dio.dart';

void main() async {
  final _dio = Dio();
  try {
    final response = await _dio.get('https://api.jikan.moe/v4/anime/21/episodes?page=1');
    print(response.data);
  } catch (e) {
    if (e is DioException) {
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
    }
  }
}
