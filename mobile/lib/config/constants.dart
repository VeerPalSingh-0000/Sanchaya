import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  // TMDB API Key from .env
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  // AniList GraphQL API
  static const String anilistGraphqlUrl = 'https://graphql.anilist.co';

  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Google Auth
  static String get googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
}
