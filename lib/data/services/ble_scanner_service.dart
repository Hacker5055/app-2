import '../../domain/models/ble_advertisement.dart';
import '../../domain/models/ble_status.dart';

/// Contract every BLE source must satisfy.
///
/// Two implementations exist:
///  * [FlutterBlueScannerService] — the real radio via flutter_blue_plus.
///  * [MockBleScannerService] — a deterministic simulator for emulators and
///    demos, so the radar UI can be explored without BLE hardware.
abstract class BleScannerService {
  /// Human readable name, used in diagnostics.
  String get name;

  bool get isMock;

  /// Normalised advertisement stream (one event per received packet).
  Stream<BleAdvertisement> get advertisements;

  /// Adapter availability updates.
  Stream<BleAdapterStatus> get adapterStatus;

  BleAdapterStatus get currentAdapterStatus;

  /// Fatal scanner errors (security exceptions, adapter failures, …).
  Stream<String> get errors;

  /// Starts (or restarts) scanning. Safe to call repeatedly.
  Future<void> start();

  /// Stops scanning but keeps the service alive.
  Future<void> stop();

  /// Tears down timers, subscriptions and platform resources.
  Future<void> dispose();
}

/// Thrown when the platform refuses to start a scan (usually a missing
/// runtime permission on Android 12+, or Bluetooth being turned off).
class BleScanException implements Exception {
  const BleScanException(this.message, {this.isPermissionError = false});

  final String message;
  final bool isPermissionError;

  @override
  String toString() => 'BleScanException: $message';
}
