import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/services/preferences_service.dart';
import '../domain/models/distance_unit.dart';
import '../domain/signal/path_loss_calculator.dart';

/// Persisted user preferences.
///
/// Every signal-processing knob (TxPower, path-loss exponent n, EMA alpha,
/// radar range) lives here so the C++-style constants in
/// [AppConstants] stay immutable and testable.
class SettingsController extends ChangeNotifier {
  SettingsController(this._preferences);

  final PreferencesService _preferences;

  static const String keyLocale = 'settings.locale';
  static const String keyUnits = 'settings.units';
  static const String keySound = 'settings.sound';
  static const String keyHaptics = 'settings.haptics';
  static const String keyMockMode = 'settings.mockMode';
  static const String keyEmaAlpha = 'settings.emaAlpha';
  static const String keyTxPower = 'settings.txPower';
  static const String keyPathLoss = 'settings.pathLossExponent';
  static const String keyRadarRange = 'settings.radarRange';

  String _localeCode = 'ar';
  DistanceUnit _units = DistanceUnit.meters;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _mockMode = false;
  double _emaAlpha = AppConstants.defaultEmaAlpha;
  double _txPower = AppConstants.defaultTxPower;
  double _pathLossExponent = AppConstants.defaultPathLossExponent;
  double _radarRange = AppConstants.defaultRadarRangeMeters;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Hydrates from disk. [systemLanguageCode] is used only on first launch.
  void load({String? systemLanguageCode}) {
    final String fallbackLanguage = systemLanguageCode == 'en' ? 'en' : 'ar';
    final String stored = _preferences.getString(keyLocale) ?? fallbackLanguage;
    _localeCode = stored == 'en' ? 'en' : 'ar';

    final String? units = _preferences.getString(keyUnits);
    _units = units == DistanceUnit.feet.name ? DistanceUnit.feet : DistanceUnit.meters;

    _soundEnabled = _preferences.getBool(keySound) ?? true;
    _hapticsEnabled = _preferences.getBool(keyHaptics) ?? true;
    _mockMode = _preferences.getBool(keyMockMode) ?? false;
    _emaAlpha = (_preferences.getDouble(keyEmaAlpha) ?? AppConstants.defaultEmaAlpha)
        .clamp(AppConstants.minEmaAlpha, AppConstants.maxEmaAlpha)
        .toDouble();
    _txPower = (_preferences.getDouble(keyTxPower) ?? AppConstants.defaultTxPower)
        .clamp(AppConstants.minTxPower, AppConstants.maxTxPower)
        .toDouble();
    _pathLossExponent =
        (_preferences.getDouble(keyPathLoss) ?? AppConstants.defaultPathLossExponent)
            .clamp(AppConstants.minPathLossExponent, AppConstants.maxPathLossExponent)
            .toDouble();
    _radarRange = (_preferences.getDouble(keyRadarRange) ?? AppConstants.defaultRadarRangeMeters)
        .clamp(AppConstants.minRadarRangeMeters, AppConstants.maxRadarRangeMeters)
        .toDouble();
    _loaded = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  String get localeCode => _localeCode;

  Locale get locale => Locale(_localeCode);

  bool get isArabic => _localeCode == 'ar';

  DistanceUnit get units => _units;

  bool get soundEnabled => _soundEnabled;

  bool get hapticsEnabled => _hapticsEnabled;

  bool get mockMode => _mockMode;

  double get emaAlpha => _emaAlpha;

  double get txPower => _txPower;

  double get pathLossExponent => _pathLossExponent;

  double get radarRange => _radarRange;

  PathLossCalculator get calculator =>
      PathLossCalculator(txPower: _txPower, pathLossExponent: _pathLossExponent);

  // ---------------------------------------------------------------------------
  // Mutators (persist in the background)
  // ---------------------------------------------------------------------------
  void _persist(Future<bool> future) {
    unawaited(future.catchError((Object _) => false));
  }

  void setLanguage(String code) {
    final String normalized = code == 'en' ? 'en' : 'ar';
    if (_localeCode == normalized) return;
    _localeCode = normalized;
    _persist(_preferences.setString(keyLocale, normalized));
    notifyListeners();
  }

  void toggleLanguage() => setLanguage(_localeCode == 'ar' ? 'en' : 'ar');

  void setUnits(DistanceUnit value) {
    if (_units == value) return;
    _units = value;
    _persist(_preferences.setString(keyUnits, value.name));
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    _persist(_preferences.setBool(keySound, value));
    notifyListeners();
  }

  void setHapticsEnabled(bool value) {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    _persist(_preferences.setBool(keyHaptics, value));
    notifyListeners();
  }

  void setMockMode(bool value) {
    if (_mockMode == value) return;
    _mockMode = value;
    _persist(_preferences.setBool(keyMockMode, value));
    notifyListeners();
  }

  void setEmaAlpha(double value) {
    final double next = value.clamp(AppConstants.minEmaAlpha, AppConstants.maxEmaAlpha).toDouble();
    if ((_emaAlpha - next).abs() < 0.0001) return;
    _emaAlpha = next;
    _persist(_preferences.setDouble(keyEmaAlpha, next));
    notifyListeners();
  }

  void setTxPower(double value) {
    final double next = value.clamp(AppConstants.minTxPower, AppConstants.maxTxPower).toDouble();
    if ((_txPower - next).abs() < 0.0001) return;
    _txPower = next;
    _persist(_preferences.setDouble(keyTxPower, next));
    notifyListeners();
  }

  void setPathLossExponent(double value) {
    final double next =
        value.clamp(AppConstants.minPathLossExponent, AppConstants.maxPathLossExponent).toDouble();
    if ((_pathLossExponent - next).abs() < 0.0001) return;
    _pathLossExponent = next;
    _persist(_preferences.setDouble(keyPathLoss, next));
    notifyListeners();
  }

  void setRadarRange(double value) {
    final double next =
        value.clamp(AppConstants.minRadarRangeMeters, AppConstants.maxRadarRangeMeters).toDouble();
    if ((_radarRange - next).abs() < 0.0001) return;
    _radarRange = next;
    _persist(_preferences.setDouble(keyRadarRange, next));
    notifyListeners();
  }

  /// Learned TxPower from a real reading at one metre.
  void applyOneMeterCalibration(double rssiAtOneMeter) {
    final double next = rssiAtOneMeter
        .clamp(AppConstants.minTxPower, AppConstants.maxTxPower)
        .toDouble();
    setTxPower(next);
  }

  /// Restores the signal pipeline defaults; language, units and mock mode stay.
  void resetSignalDefaults() {
    _emaAlpha = AppConstants.defaultEmaAlpha;
    _txPower = AppConstants.defaultTxPower;
    _pathLossExponent = AppConstants.defaultPathLossExponent;
    _radarRange = AppConstants.defaultRadarRangeMeters;
    _persist(_preferences.setDouble(keyEmaAlpha, _emaAlpha));
    _persist(_preferences.setDouble(keyTxPower, _txPower));
    _persist(_preferences.setDouble(keyPathLoss, _pathLossExponent));
    _persist(_preferences.setDouble(keyRadarRange, _radarRange));
    notifyListeners();
  }
}
