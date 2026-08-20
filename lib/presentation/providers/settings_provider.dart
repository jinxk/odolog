import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

/// User settings that persist across launches: the theme mode, the currency
/// symbol, and whether each reminder category is on. Stored in
/// shared_preferences, which keeps this off the database.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.currencySymbol,
    required this.documentRemindersEnabled,
    required this.serviceRemindersEnabled,
  });

  final ThemeMode themeMode;
  final String currencySymbol;

  /// Insurance, PUC, RC and fitness expiry reminders. On by default.
  final bool documentRemindersEnabled;

  /// Engine oil and general service reminders. On by default.
  final bool serviceRemindersEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currencySymbol,
    bool? documentRemindersEnabled,
    bool? serviceRemindersEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      documentRemindersEnabled:
          documentRemindersEnabled ?? this.documentRemindersEnabled,
      serviceRemindersEnabled:
          serviceRemindersEnabled ?? this.serviceRemindersEnabled,
    );
  }
}

const _themeKey = 'settings.themeMode';
const _currencyKey = 'settings.currencySymbol';
const _documentRemindersKey = 'settings.documentReminders';
const _serviceRemindersKey = 'settings.serviceReminders';
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
      documentRemindersEnabled: prefs.getBool(_documentRemindersKey) ?? true,
      serviceRemindersEnabled: prefs.getBool(_serviceRemindersKey) ?? true,
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

  Future<void> setDocumentRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_documentRemindersKey, value);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(documentRemindersEnabled: value));
    }
  }

  Future<void> setServiceRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_serviceRemindersKey, value);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(serviceRemindersEnabled: value));
    }
  }
}
