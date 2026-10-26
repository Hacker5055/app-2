import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/services/compass_service.dart';
import '../domain/models/ble_device.dart';
import '../domain/signal/azimuth_estimator.dart';
import 'ble_controller.dart';

enum SweepPhase { idle, running, complete }

/// 360° direction finder.
///
/// BLE RSSI has no intrinsic direction, so the only way a phone can locate a
/// tag is to rotate around its own axis and observe the signal envelope. This
/// controller:
///
/// 1. reads the magnetometer (or simulates rotation on devices without one),
/// 2. accumulates absolute rotation until a full circle is covered,
/// 3. samples the smoothed RSSI every ~4° of rotation,
/// 4. fuses the samples with [AzimuthEstimator] into a heading + confidence,
/// 5. writes the winning bearing back onto the device's radar node.
class SweepAssistantController extends ChangeNotifier {
  SweepAssistantController({
    required BleController bleController,
    required CompassService compassService,
    required this.deviceId,
    required this.simulateRotation,
  })  : _ble = bleController,
        _compass = compassService;

  final BleController _ble;
  final CompassService _compass;
  final String deviceId;

  /// Demo mode / emulator: rotate a virtual dial instead of reading hardware.
  final bool simulateRotation;

  static const Duration _tick = Duration(milliseconds: 50);
  static const double _simulatedDegreesPerTick = 3.0;
  static const double _sampleSpacingDegrees = 4.0;

  final List<SweepSample> _samples = <SweepSample>[];

  StreamSubscription<double>? _headingSubscription;
  Timer? _simulationTimer;
  Timer? _watchdog;

  SweepPhase _phase = SweepPhase.idle;
  double _lastHeading = 0;
  double _lastSampleHeading = double.negativeInfinity;
  double _accumulatedDegrees = 0;
  double _liveHeading = 0;
  SweepResult? _result;
  bool _usingSimulation = false;
  bool _disposed = false;

  SweepPhase get phase => _phase;

  bool get isRunning => _phase == SweepPhase.running;

  bool get isComplete => _phase == SweepPhase.complete;

  bool get usingSimulation => _usingSimulation;

  double get progress => (_accumulatedDegrees / 360.0).clamp(0.0, 1.0).toDouble();

  int get degreesRemaining => (360 - _accumulatedDegrees).clamp(0, 360).round();

  double get liveHeading => _liveHeading;

  int get sampleCount => _samples.length;

  SweepResult? get result => _result;

  BleDevice? get device => _ble.deviceById(deviceId);

  void start() {
    if (_disposed) return;
    _resetSession();
    _phase = SweepPhase.running;
    notifyListeners();

    final bool compassUsable = !simulateRotation && _compass.isSupported;
    if (compassUsable) {
      _usingSimulation = false;
      _headingSubscription = _compass.headings.listen(
        _onHeading,
        onError: (Object error) {
          debugPrint('Compass error during sweep: $error');
          _fallBackToSimulation();
        },
      );
      _watchdog = Timer(const Duration(milliseconds: 2200), () {
        if (_phase == SweepPhase.running && _samples.isEmpty) {
          _fallBackToSimulation();
        }
      });
    } else {
      _startSimulation();
    }
  }

  void restart() => start();

  void _resetSession() {
    _headingSubscription?.cancel();
    _headingSubscription = null;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _watchdog?.cancel();
    _watchdog = null;
    _samples.clear();
    _accumulatedDegrees = 0;
    _lastHeading = 0;
    _lastSampleHeading = double.negativeInfinity;
    _liveHeading = 0;
    _result = null;
    _usingSimulation = false;
  }

  void _fallBackToSimulation() {
    if (_phase != SweepPhase.running) return;
    _headingSubscription?.cancel();
    _headingSubscription = null;
    _watchdog?.cancel();
    _startSimulation();
  }

  void _startSimulation() {
    _usingSimulation = true;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(_tick, (Timer _) {
      _onHeading((_liveHeading + _simulatedDegreesPerTick) % 360);
    });
    notifyListeners();
  }

  void _onHeading(double heading) {
    if (_phase != SweepPhase.running || _disposed) return;

    final double normalized = (heading % 360 + 360) % 360;
    if (_samples.isNotEmpty) {
      double delta = (normalized - _lastHeading).abs();
      if (delta > 180) delta = 360 - delta;
      _accumulatedDegrees += delta;
    }
    _lastHeading = normalized;
    _liveHeading = normalized;

    final double spacing = _samples.isEmpty
        ? double.infinity
        : _angularDistance(normalized, _lastSampleHeading);
    if (spacing >= _sampleSpacingDegrees) {
      _addSample(normalized);
    }

    if (_accumulatedDegrees >= 360) {
      _complete();
      return;
    }
    notifyListeners();
  }

  void _addSample(double heading) {
    final BleDevice? current = device;
    final double rssi = _ble.latestSmoothedRssi(deviceId) ?? current?.smoothedRssi ?? -75.0;
    _samples.add(
      SweepSample(
        headingDegrees: heading,
        rssi: rssi,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _lastSampleHeading = heading;
  }

  static double _angularDistance(double a, double b) {
    double delta = (a - b).abs() % 360;
    if (delta > 180) delta = 360 - delta;
    return delta;
  }

  void _complete() {
    _phase = SweepPhase.complete;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _headingSubscription?.cancel();
    _headingSubscription = null;
    _watchdog?.cancel();
    _watchdog = null;

    final SweepResult? estimate = AzimuthEstimator.estimate(
      List<SweepSample>.of(_samples),
      coverageDegrees: math.min(_accumulatedDegrees, 360),
      isComplete: true,
    );
    _result = estimate;
    if (estimate != null) {
      _ble.applyBearing(deviceId, estimate.headingRadians);
    }
    notifyListeners();
  }

  /// Re-applies the winning heading, e.g. after the user panned the radar.
  void lockBearing() {
    final SweepResult? estimate = _result;
    if (estimate == null) return;
    _ble.applyBearing(deviceId, estimate.headingRadians);
    notifyListeners();
  }

  void cancel() {
    _resetSession();
    _phase = SweepPhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _resetSession();
    super.dispose();
  }
}
