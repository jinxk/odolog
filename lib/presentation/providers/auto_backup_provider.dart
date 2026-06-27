import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/backup/auto_backup_policy.dart';
import 'repositories.dart';
import 'usecases.dart';

part 'auto_backup_provider.g.dart';

const _enabledKey = 'autoBackup.enabled';
const _consentAskedKey = 'autoBackup.consentAsked';
const _lastDayKey = 'autoBackup.lastDay';
const _lastAtKey = 'autoBackup.lastAt';

/// A snapshot of the auto backup feature for the settings screen and the first
/// launch consent prompt: whether the platform can do it at all, whether the
/// user has it on, whether the one time consent has been answered, and when the
/// last backup landed.
class AutoBackupState {
  const AutoBackupState({
    required this.available,
    required this.enabled,
    required this.consentAsked,
    required this.lastBackupAt,
  });

  /// The platform supports uninstall surviving backups (Android 10 or newer).
  final bool available;

  /// The user preference, on by default but only acted on once consent has
  /// been answered.
  final bool enabled;

  /// Whether the one time consent prompt has been answered either way.
  final bool consentAsked;

  final DateTime? lastBackupAt;

  /// On, allowed, and consented: the three conditions that must hold before the
  /// once a day debounce even comes into it.
  bool get active => available && enabled && consentAsked;

  AutoBackupState copyWith({
    bool? available,
    bool? enabled,
    bool? consentAsked,
    DateTime? lastBackupAt,
  }) {
    return AutoBackupState(
      available: available ?? this.available,
      enabled: enabled ?? this.enabled,
      consentAsked: consentAsked ?? this.consentAsked,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }
}

/// Coordinates the automatic backup: it owns the on/off preference and the one
/// time consent, and it holds the once a day debounce so a backup runs at most
/// once per calendar day no matter how many writes trigger it. Kept alive for
/// the app's lifetime. Every screen that completes a data write calls
/// [runIfDue], which is the single place the debounce and the write live; the
/// screens themselves carry no backup logic.
@Riverpod(keepAlive: true)
class AutoBackup extends _$AutoBackup {
  @override
  Future<AutoBackupState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final availability = await ref.read(autoBackupWriterProvider).isAvailable();
    final available = availability.getRight().toNullable() ?? false;
    final lastAt = prefs.getInt(_lastAtKey);
    return AutoBackupState(
      available: available,
      enabled: prefs.getBool(_enabledKey) ?? true,
      consentAsked: prefs.getBool(_consentAskedKey) ?? false,
      lastBackupAt: lastAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastAt),
    );
  }

  /// Turns the feature on or off from the settings toggle. Flipping the switch
  /// also counts as answering the one time consent, so the toggle is the whole
  /// decision once the user has found it. Turning it on takes a backup right
  /// away if one is due.
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    await prefs.setBool(_consentAskedKey, true);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(enabled: value, consentAsked: true));
    }
    if (value) unawaited(runIfDue());
  }

  /// Records the answer to the first launch consent prompt. Declining leaves
  /// the feature off; accepting turns it on and takes the first backup now.
  Future<void> recordConsent({required bool accepted}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentAskedKey, true);
    await prefs.setBool(_enabledKey, accepted);
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(enabled: accepted, consentAsked: true),
      );
    }
    if (accepted) unawaited(runIfDue());
  }

  /// Writes a backup when the feature is active and today's has not been
  /// written yet. Safe to call after any data write: it is cheap when nothing
  /// is due, and silent when it fails, since a backup the user never explicitly
  /// asked for should not interrupt them with an error. Fire and forget.
  Future<void> runIfDue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_enabledKey) ?? true;
      final consentAsked = prefs.getBool(_consentAskedKey) ?? false;
      if (!enabled || !consentAsked) return;
      final now = DateTime.now();
      if (!AutoBackupPolicy.isDue(prefs.getString(_lastDayKey), now)) return;
      final availability = await ref
          .read(autoBackupWriterProvider)
          .isAvailable();
      if (availability.getRight().toNullable() != true) return;
      final result = await ref.read(runAutoBackupProvider).execute(now: now);
      if (result.isRight()) {
        await prefs.setString(_lastDayKey, AutoBackupPolicy.dayStamp(now));
        await prefs.setInt(_lastAtKey, now.millisecondsSinceEpoch);
        final current = state.value;
        if (current != null) {
          state = AsyncData(current.copyWith(lastBackupAt: now));
        }
      }
    } catch (_) {
      // Auto backup is best effort; its failure never reaches the user.
    }
  }
}
