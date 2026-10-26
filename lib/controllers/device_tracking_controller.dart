import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/services/audio_service.dart';
import '../data/services/haptics_service.dart';
import '../domain/models/ble_device.dart';
import '../domain/models/proximity_zone.dart';
import '../domain/signal/proximity_pulse.dart';
import 'ble_controller.dart';
import 'settings_controller.dart';

/// Drives the Geiger-counter feedback while a single device is being tracked.
///
/// The cadence is recalculated from the live distance on every BLE snapshot
/// (1 Hz) and sampled on a 50 ms scheduler, which is fine-grained enough for
/// the 130 ms hot-zone interval without keeping the CPU awake.
class DeviceTrackingController extends ChangeNotifier {
  DeviceTrackingController({
    required BleController bleController,
    required SettingsController settings,
    required AudioService audio,
    required HapticsService haptics,
  })  : _ble = bleController,
        _settings = settings,
        _audio = audio,
        _haptics = haptics {
    _ble.addListener(_onBleChanged);
    _settings.addListener(_onSettingsChanged);
    _haptics.enabled = _settings.hapticsEnabled;
    _audio.enabled = _settings.soundEnabled;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (Timer _) => _tick());
  }

  final BleController _ble;
  final SettingsController _settings;
  final AudioService _audio;
  final HapticsService _haptics;

  final Stopwatch _clock = Stopwatch()..start();
  Timer? _timer;

  String? _deviceId;
  bool _foreground = true;
  bool _geigerEnabled = true;
  int _lastPingMs = 0;
  int _lastHapticMs = 0;
  int _pulseSerial = 0;
  double _lastIntensity = 0;
  bool _disposed = false;

  String? get deviceId => _deviceId;

  BleDevice? get device => _ble.deviceById(_deviceId);

  bool get isActive => _deviceId != null;

  bool get isForeground => _foreground;

  bool get isGeigerEnabled => _geigerEnabled;

  /// Increments on every ping — widgets use it to fire ripple animations.
  int get pulseSerial => _pulseSerial;

  double get lastIntensity => _lastIntensity;

  /// Current time between pings (for the UI readout).
  int get currentIntervalMs {
    final BleDevice? current = device;
    if (current == null) return 0;
    return ProximityPulse.intervalForDistance(current.distanceMeters, maxRange: _settings.radarRange).inMilliseconds;
  }

  void attach(String deviceId) {
    _deviceId = deviceId;
    _lastPingMs = _clock.elapsedMilliseconds;
    _lastHapticMs = _clock.elapsedMilliseconds;
    notifyListeners();
  }

  void detach() {
    _deviceId = null;
    notifyListeners();
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    if (!value) {
      unawaited(_audio.stopPing());
    } else {
      _lastPingMs = _clock.elapsedMilliseconds;
      _lastHapticMs = _clock.elapsedMilliseconds;
    }
    notifyListeners();
  }

  void toggleGeiger() {
    _geigerEnabled = !_geigerEnabled;
    if (!_geigerEnabled) unawaited(_audio.stopPing());
    notifyListeners();
  }

  PingTone _toneFor(ProximityZone zone) => switch (zone) {
        ProximityZone.hot => PingTone.hot,
        ProximityZone.warm => PingTone.warm,
        ProximityZone.moderate || ProximityZone.cold => PingTone.cold,
      };

  void _tick() {
    if (_disposed || !_foreground || !_geigerEnabled) return;
    final BleDevice? current = device;
    if (current == null) return;

    final double maxRange = _settings.radarRange;
    final int nowMs = _clock.elapsedMilliseconds;
    final int pingInterval =
        ProximityPulse.intervalForDistance(current.distanceMeters, maxRange: maxRange).inMilliseconds;
    final int hapticInterval =
        ProximityPulse.hapticIntervalForDistance(current.distanceMeters, maxRange: maxRange).inMilliseconds;

    if (nowMs - _lastPingMs >= pingInterval) {
      _lastPingMs = nowMs;
      _pulseSerial++;
      _lastIntensity = ProximityPulse.intensityForDistance(current.distanceMeters, maxRange: maxRange);
      final double volume = ProximityPulse.volumeForDistance(current.distanceMeters, maxRange: maxRange);
      if (_settings.soundEnabled) {
        unawaited(_audio.ping(volume: volume, tone: _toneFor(current.zone)));
      }
      notifyListeners();
    }

    if (nowMs - _lastHapticMs >= hapticInterval) {
      _lastHapticMs = nowMs;
      if (_settings.hapticsEnabled) {
        unawaited(_haptics.tick(current.zone.intensity));
      }
    }
  }

  void _onBleChanged() => notifyListeners();

  void _onSettingsChanged() {
    _haptics.enabled = _settings.hapticsEnabled;
    _audio.enabled = _settings.soundEnabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _ble.removeListener(_onBleChanged);
    _settings.removeListener(_onSettingsChanged);
    unawaited(_audio.stopPing());
    super.dispose();
  }
}
