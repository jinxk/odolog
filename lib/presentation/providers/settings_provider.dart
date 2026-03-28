import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

/// User settings that persist across launches: the theme mode and the currency
/// symbol. Stored in shared_preferences, which keeps this off the database.
class AppSettings {
  const AppSettings({required this.themeMode, required this.currencySymbol});

  final ThemeMode themeMode;
  final String currencySymbol;

  AppSettings copyWith({ThemeMode? themeMode, String? currencySymbol}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}

const _themeKey = 'settings.themeMode';
const _currencyKey = 'settings.currencySymbol';
const _defaultCurrency = 'Rs';

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      currencySymbol: prefs.getString(_currencyKey) ?? _defaultCurrency,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(themeMode: mode));
  }

  Future<void> setCurrencySymbol(String symbol) async {
    final trimmed = symbol.trim().isEmpty ? _defaultCurrency : symbol.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, trimmed);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(currencySymbol: trimmed));
    }
  }
}
