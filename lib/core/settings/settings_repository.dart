import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  const SettingsRepository(this._preferences);

  static const _snapshotKey = 'import.save_raw_snapshot';
  static const _themeKey = 'appearance.theme_mode';
  static const _primaryColorKey = 'appearance.primary_color';
  static const _fontSizeKey = 'appearance.font_size';
  static const _languageKey = 'appearance.language';
  static const _aiApiKey = 'ai.api_key';
  static const _aiFirstOpenedAtKey = 'ai.first_opened_at';
  static const _userAgreementAcceptedKey = 'legal.user_agreement.accepted';
  static const _visibleSectionCountKey = 'schedule.visible_section_count';
  static const _showOffWeekCoursesKey = 'schedule.show_off_week_courses';
  static const _courseColorOverridesKey = 'schedule.course_color_overrides';

  final SharedPreferences _preferences;

  bool get saveImportSnapshots => _preferences.getBool(_snapshotKey) ?? true;

  Future<void> setSaveImportSnapshots(bool value) =>
      _preferences.setBool(_snapshotKey, value);

  String get themeModeName => _preferences.getString(_themeKey) ?? 'light';

  Future<void> setThemeModeName(String value) =>
      _preferences.setString(_themeKey, value);

  int get primaryColorValue =>
      _preferences.getInt(_primaryColorKey) ?? 0xFF005BAC;

  Future<void> setPrimaryColorValue(int value) =>
      _preferences.setInt(_primaryColorKey, value);

  String get fontSizeName => _preferences.getString(_fontSizeKey) ?? 'medium';

  double get fontScale {
    return switch (fontSizeName) {
      'small' => 0.84,
      'large' => 1.24,
      _ => 1.0,
    };
  }

  Future<void> setFontSizeName(String value) =>
      _preferences.setString(_fontSizeKey, value);

  String get languageCode => _preferences.getString(_languageKey) ?? 'zh';

  Future<void> setLanguageCode(String value) =>
      _preferences.setString(_languageKey, value);

  int get visibleSectionCount {
    final value = _preferences.getInt(_visibleSectionCountKey) ?? 13;
    return value.clamp(1, 13);
  }

  Future<void> setVisibleSectionCount(int value) =>
      _preferences.setInt(_visibleSectionCountKey, value.clamp(1, 13));

  bool get showOffWeekCourses =>
      _preferences.getBool(_showOffWeekCoursesKey) ?? false;

  Future<void> setShowOffWeekCourses(bool value) =>
      _preferences.setBool(_showOffWeekCoursesKey, value);

  Map<String, int> get courseColorOverrides {
    final raw = _preferences.getString(_courseColorOverridesKey);
    if (raw == null || raw.trim().isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }
      return decoded.map((key, value) {
        if (value is int) {
          return MapEntry(key, value);
        }
        return MapEntry(key, int.tryParse(value.toString()) ?? 0xFF005BAC);
      });
    } on Object {
      return const {};
    }
  }

  Future<void> setCourseColorOverride(String courseName, int colorValue) async {
    final normalizedName = courseName.trim();
    if (normalizedName.isEmpty) {
      return;
    }
    final overrides = Map<String, int>.from(courseColorOverrides);
    overrides[normalizedName] = colorValue;
    await _preferences.setString(
      _courseColorOverridesKey,
      jsonEncode(overrides),
    );
  }

  Future<void> clearCourseColorOverride(String courseName) async {
    final normalizedName = courseName.trim();
    if (normalizedName.isEmpty) {
      return;
    }
    final overrides = Map<String, int>.from(courseColorOverrides)
      ..remove(normalizedName);
    await _preferences.setString(
      _courseColorOverridesKey,
      jsonEncode(overrides),
    );
  }

  Future<void> clearAllCourseColorOverrides() =>
      _preferences.remove(_courseColorOverridesKey);

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

  bool get userAgreementAccepted =>
      _preferences.getBool(_userAgreementAcceptedKey) ?? false;

  Future<void> acceptUserAgreement() =>
      _preferences.setBool(_userAgreementAcceptedKey, true);

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
