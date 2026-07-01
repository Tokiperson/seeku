import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  const SettingsRepository(this._preferences);

  static const _snapshotKey = 'import.save_raw_snapshot';
  static const _themeKey = 'appearance.theme_mode';

  final SharedPreferences _preferences;

  bool get saveImportSnapshots => _preferences.getBool(_snapshotKey) ?? true;

  Future<void> setSaveImportSnapshots(bool value) =>
      _preferences.setBool(_snapshotKey, value);

  String get themeModeName => _preferences.getString(_themeKey) ?? 'system';

  Future<void> setThemeModeName(String value) =>
      _preferences.setString(_themeKey, value);
}
