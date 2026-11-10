class AppConstants {
  static const String appName = 'CineTrack';

  // API Güvenlik Anahtarı (X-API-KEY)
  static const String apiKeyHeader = 'X-API-KEY';
  static const String apiKey = 'cinetrack_sec_api_key_2026_x89a';

  // API Base URL (Canlı Sunucu)
  static const String apiBaseUrl = 'http://dizizi.net/cinetrack/api';

  // TMDB Poster & Backdrop Base URLs
  static const String tmdbImageBaseW500 = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbImageBaseOriginal = 'https://image.tmdb.org/t/p/original';

  static String getPosterUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/500x750?text=No+Poster';
    }
    if (path.startsWith('http')) return path;
    return '$tmdbImageBaseW500$path';
  }

  static String getBackdropUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/1280x720?text=No+Backdrop';
    }
    if (path.startsWith('http')) return path;
    return '$tmdbImageBaseOriginal$path';
  }
}

