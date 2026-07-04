class Constants {
  // TMDB API Key from .env
  static const String tmdbApiKey = 'd60e665c617655185db02ee381c7bd0a';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://wsrv.nl/?url=https://image.tmdb.org/t/p';

  // AniList GraphQL API
  static const String anilistGraphqlUrl = 'https://graphql.anilist.co';

  // Supabase Configuration
  // Extracted from Prisma URL: postgres.qpxaznkndunxoxnywgfe...
  static const String supabaseUrl = 'https://qpxaznkndunxoxnywgfe.supabase.co';
  // TODO: Replace with the actual anon key from your Supabase project dashboard
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFweGF6bmtuZHVueG94bnl3Z2ZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjgyNjgsImV4cCI6MjA5NzU0NDI2OH0.LgjuUxhMJHXucwpS9yaD3rZ3Q0Dg8a6-peNkk0MpDUU';

  // Google Auth
  static const String googleWebClientId = '651402582936-30hr4lqc4ih6eu6e68fgsk2tp5qf4aso.apps.googleusercontent.com';
}
