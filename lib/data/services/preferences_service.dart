import 'package:shared_preferences/shared_preferences.dart';

/// Narrow wrapper around SharedPreferences so controllers never depend on the
/// plugin directly (and can be unit-tested with mock preferences).
class PreferencesService {
  const PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  String? getString(String key) => _preferences.getString(key);

  bool? getBool(String key) => _preferences.getBool(key);

  double? getDouble(String key) => _preferences.getDouble(key);

  int? getInt(String key) => _preferences.getInt(key);

  Future<bool> setString(String key, String value) => _preferences.setString(key, value);

  Future<bool> setBool(String key, bool value) => _preferences.setBool(key, value);

  Future<bool> setDouble(String key, double value) => _preferences.setDouble(key, value);

  Future<bool> setInt(String key, int value) => _preferences.setInt(key, value);
}
