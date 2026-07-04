import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  const SettingsRepository(this._preferences);

  static const _snapshotKey = 'import.save_raw_snapshot';
  static const _themeKey = 'appearance.theme_mode';
  static const _aiApiKey = 'ai.api_key';
  static const _aiFirstOpenedAtKey = 'ai.first_opened_at';

  final SharedPreferences _preferences;

  bool get saveImportSnapshots => _preferences.getBool(_snapshotKey) ?? true;

  Future<void> setSaveImportSnapshots(bool value) =>
      _preferences.setBool(_snapshotKey, value);

  String get themeModeName => _preferences.getString(_themeKey) ?? 'system';

  Future<void> setThemeModeName(String value) =>
      _preferences.setString(_themeKey, value);

  String? get aiApiKey {
    final value = _preferences.getString(_aiApiKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  bool get hasAiApiKey => aiApiKey != null;

  Future<void> setAiApiKey(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      await clearAiApiKey();
      return;
    }
    await _preferences.setString(_aiApiKey, normalized);
  }

  Future<void> clearAiApiKey() => _preferences.remove(_aiApiKey);

  DateTime? get aiFirstOpenedAt {
    final value = _preferences.getString(_aiFirstOpenedAtKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<DateTime> ensureAiFirstOpenedAt({DateTime? now}) async {
    final existing = aiFirstOpenedAt;
    if (existing != null) {
      return existing;
    }
    final openedAt = now ?? DateTime.now();
    await _preferences.setString(
      _aiFirstOpenedAtKey,
      openedAt.toIso8601String(),
    );
    return openedAt;
  }

  int builtInTrialElapsedDays({DateTime? now}) {
    final openedAt = aiFirstOpenedAt;
    if (openedAt == null) {
      return 0;
    }
    final current = now ?? DateTime.now();
    final elapsed = current.difference(openedAt).inDays;
    return elapsed < 0 ? 0 : elapsed;
  }

  bool isBuiltInTrialAllowed({DateTime? now}) =>
      builtInTrialElapsedDays(now: now) < 5;

  int builtInTrialRemainingDays({DateTime? now}) {
    final remaining = 5 - builtInTrialElapsedDays(now: now);
    return remaining < 0 ? 0 : remaining;
  }
}
