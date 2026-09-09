import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'fa_locale_code';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main()');
});

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale?>((ref) {
  return LocaleController(ref.watch(sharedPreferencesProvider));
});

Future<void> ensureDateFormatting(String languageCode) async {
  await initializeDateFormatting(languageCode);
}

/// Langue choisie dès le premier écran (source locale + sync API plus tard).
class LocaleController extends StateNotifier<Locale?> {
  LocaleController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static Locale? _read(SharedPreferences prefs) {
    final code = prefs.getString(_localeKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  bool get hasChosenLanguage => state != null;

  Future<void> setLocale(Locale locale) async {
    await ensureDateFormatting(locale.languageCode);
    await _prefs.setString(_localeKey, locale.languageCode);
    state = locale;
  }
}
