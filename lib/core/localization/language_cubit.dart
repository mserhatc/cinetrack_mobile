import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<Locale> {
  static const String _prefKey = 'selected_language';

  LanguageCubit() : super(const Locale('tr', 'TR')) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_prefKey) ?? 'tr';
    emit(Locale(langCode));
  }

  Future<void> changeLanguage(String langCode) async {
    if (state.languageCode == langCode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
    emit(Locale(langCode));
  }

  void toggleLanguage() {
    if (state.languageCode == 'tr') {
      changeLanguage('en');
    } else {
      changeLanguage('tr');
    }
  }
}

