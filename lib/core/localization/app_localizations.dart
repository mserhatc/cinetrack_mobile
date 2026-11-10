import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('tr', 'TR'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'tr': {
      'app_title': 'CineTrack',
      'home': 'Ana Sayfa',
      'new_post': 'Yeni Paylaşım',
      'profile': 'Ben',
      'login': 'Giriş Yap',
      'register': 'Kayıt Ol',
      'logout': 'Çıkış Yap',
      'email': 'E-posta',
      'username': 'Kullanıcı Adı',
      'password': 'Şifre',
      'full_name': 'Ad Soyad',
      'bio': 'Hakkında / Biyografi',
      'followers': 'Takipçi',
      'following': 'Takip Edilen',
      'watched_movies': 'İzlenen Film',
      'watched_shows': 'İzlenen Dizi',
      'posts': 'Gönderiler',
      'quotes': 'Replikler',
      'reviews': 'Yorumlar',
      'post_quote': 'Replik Paylaş',
      'post_review': 'Yorum Paylaş',
      'search_media': 'Film veya Dizi Ara...',
      'write_quote': 'Filmden bir replik yazın...',
      'write_review': 'Düşüncelerinizi ve yorumunuzu yazın...',
      'share': 'Paylaş',
      'like': 'Beğen',
      'comment': 'Yorum',
      'comments': 'Yorumlar',
      'rate': 'Puan Ver',
      'add_watchlist': 'İzleme Listesine Ekle',
      'mark_watched': 'İzlendi Olarak İşaretle',
      'in_watchlist': 'Listede',
      'watched': 'İzlendi',
      'trending': 'Gündemdekiler',
      'popular_movies': 'Popüler Filmler',
      'popular_tv': 'Popüler Diziler',
      'theme_dark': 'Karanlık Tema',
      'theme_light': 'Aydınlık Tema',
      'language': 'Dil / Language',
      'no_posts_yet': 'Henüz bir paylaşım yapılmamış.',
      'must_login': 'Bu işlemi yapmak için lütfen giriş yapın.',
      'login_welcome': 'Hoş Geldiniz!',
      'login_sub': 'Film ve dizi dünyasındaki paylaşımları keşfet.',
      'dont_have_account': 'Hesabınız yok mu? Kayıt Olun',
      'already_have_account': 'Zaten hesabınız var mı? Giriş Yapın',
      'follow': 'Takip Et',
      'unfollow': 'Takipten Çık',
    },
    'en': {
      'app_title': 'CineTrack',
      'home': 'Home',
      'new_post': 'New Post',
      'profile': 'Me',
      'login': 'Log In',
      'register': 'Sign Up',
      'logout': 'Log Out',
      'email': 'Email',
      'username': 'Username',
      'password': 'Password',
      'full_name': 'Full Name',
      'bio': 'About / Bio',
      'followers': 'Followers',
      'following': 'Following',
      'watched_movies': 'Movies Watched',
      'watched_shows': 'Shows Watched',
      'posts': 'Posts',
      'quotes': 'Quotes',
      'reviews': 'Reviews',
      'post_quote': 'Share Quote',
      'post_review': 'Share Review',
      'search_media': 'Search Movie or Show...',
      'write_quote': 'Write a memorable quote...',
      'write_review': 'Write your thoughts and review...',
      'share': 'Share',
      'like': 'Like',
      'comment': 'Comment',
      'comments': 'Comments',
      'rate': 'Rate',
      'add_watchlist': 'Add to Watchlist',
      'mark_watched': 'Mark as Watched',
      'in_watchlist': 'In Watchlist',
      'watched': 'Watched',
      'trending': 'Trending',
      'popular_movies': 'Popular Movies',
      'popular_tv': 'Popular TV Shows',
      'theme_dark': 'Dark Theme',
      'theme_light': 'Light Theme',
      'language': 'Language',
      'no_posts_yet': 'No posts yet.',
      'must_login': 'Please log in to continue.',
      'login_welcome': 'Welcome!',
      'login_sub': 'Explore movie & TV show community posts.',
      'dont_have_account': "Don't have an account? Sign Up",
      'already_have_account': 'Already have an account? Log In',
      'follow': 'Follow',
      'unfollow': 'Unfollow',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ?? _localizedValues['tr']?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['tr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

