import 'package:dio/dio.dart';

void main() async {
  final _dio = Dio();
  int idMal = 21;
  int page = 1;
  bool hasNextPage = true;
  int total = 0;

  while (hasNextPage && page <= 5) {
    try {
      print('Fetching page $page...');
      final response = await _dio.get(
        'https://api.jikan.moe/v4/anime/$idMal/episodes?page=$page',
      );
      final data = response.data['data'] as List<dynamic>?;
      if (data == null) {
        print('Data is null');
        break;
      }
      
      total += data.length;
      hasNextPage = response.data['pagination']?['has_next_page'] ?? false;
      print('Page $page fetched. Total: $total, hasNext: $hasNextPage');
      
      if (hasNextPage) {
        page++;
        await Future.delayed(const Duration(milliseconds: 350));
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) {
        print('429, waiting 1s');
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
      print('Error: $e');
      break;
    }
  }
}
