import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrack_mobile/core/api/api_client.dart';
import 'package:cinetrack_mobile/core/localization/language_cubit.dart';
import 'package:cinetrack_mobile/core/theme/theme_cubit.dart';
import 'package:cinetrack_mobile/features/auth/cubit/auth_cubit.dart';
import 'package:cinetrack_mobile/features/feed/cubit/feed_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CineTrack Mobil State & Core Testleri', () {
    test('ThemeCubit varsayilan koyu tema ve degisim testi', () async {
      final cubit = ThemeCubit();
      expect(cubit.state, ThemeMode.dark);
      await cubit.toggleTheme();
      expect(cubit.state, ThemeMode.light);
      await cubit.toggleTheme();
      expect(cubit.state, ThemeMode.dark);
    });

    test('LanguageCubit varsayilan Turkce ve Ingilizce gecis testi', () async {
      final cubit = LanguageCubit();
      expect(cubit.state.languageCode, 'tr');
      await cubit.changeLanguage('en');
      expect(cubit.state.languageCode, 'en');
      await cubit.changeLanguage('tr');
      expect(cubit.state.languageCode, 'tr');
    });
  });

  group('CineTrack Mobil - Backend & MySQL Canli Entegrasyon Testleri', () {
    final api = ApiClient();

    test('1. Backend /api/feed akisi MySQL uzerinden basariyla geliyor mu', () async {
      final response = await api.get('/feed');
      expect(response['status'], true);
      expect(response['data'], isA<List>());
      final posts = response['data'] as List;
      expect(posts.isNotEmpty, true);
      print('✓ Gelen Post Sayisi: ${posts.length}');
      print('✓ Ilk Post Basligi: ${posts[0]['title']} (Tipi: ${posts[0]['post_type']})');
    });

    test('2. Backend /api/auth/login ile giris yapilip token aliniyor mu', () async {
      final response = await api.post('/auth/login', body: {
        'login': 'ahmet_film',
        'password': 'password',
      });
      expect(response['status'], true);
      expect(response['data']['token'], isNotNull);
      final token = response['data']['token'];
      api.setToken(token);
      print('✓ Alinan Auth Token: $token');
    });

    test('3. Backend /api/auth/profile kullanici istatistiklerini hesapliyor mu', () async {
      final response = await api.get('/auth/profile');
      expect(response['status'], true);
      final stats = response['data']['stats'];
      expect(stats, isNotNull);
      print('✓ Takipci: ${stats['followers']}');
      print('✓ Takip Edilen: ${stats['following']}');
      print('✓ Izlenen Film: ${stats['watched_movies']}');
      print('✓ Izlenen Dizi: ${stats['watched_shows']}');
      expect(stats['watched_movies'], greaterThanOrEqualTo(1));
    });

    test('4. Backend /api/tmdb/trending TMDB tokenlari ile trendleri getiriyor mu', () async {
      final response = await api.get('/tmdb/trending');
      expect(response['results'], isA<List>());
      final results = response['results'] as List;
      expect(results.isNotEmpty, true);
      final firstMedia = results[0];
      print('✓ TMDB Trend: ${firstMedia['title'] ?? firstMedia['name']} (ID: ${firstMedia['id']})');
    });

    test('5. Mobil /api/feed/create ile yeni replik postu MySQL e kaydediliyor mu', () async {
      final response = await api.post('/feed/create', body: {
        'post_type': 'quote',
        'title': 'The Matrix',
        'quote_text': 'Mavi hapi alirsan hikaye biter, kirmizi hapi alirsan harikalar diyarinda kalirsin.',
        'content': 'Sinema tarihinin en ikonik sahnesi.',
        'rating': 9.8,
        'tmdb_id': 603,
        'media_type': 'movie',
        'poster_path': '/pFlaoHTZeyNkG83vxsAJiGzfSsa.jpg',
      });
      expect(response['status'], true);
      final created = response['data'];
      expect(created['title'], 'The Matrix');
      print('✓ Olusturulan Post ID: ${created['id']}');

      // Beğeni testi
      final likeResp = await api.post('/feed/like/${created['id']}');
      expect(likeResp['status'], true);
      expect(likeResp['data']['is_liked'], true);
      print('✓ Post Begenildi, Begeni Sayisi: ${likeResp['data']['likes_count']}');
    });
  });
}

