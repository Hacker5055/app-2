import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of a runtime permission attempt.
@immutable
class PermissionOutcome {
  const PermissionOutcome({
    required this.granted,
    required this.permanentlyDenied,
    this.failure,
  });

  final bool granted;
  final bool permanentlyDenied;
  final String? failure;

  @override
  String toString() =>
      'PermissionOutcome(granted: $granted, permanentlyDenied: $permanentlyDenied, failure: $failure)';
}

/// Wraps the Android runtime permission flow.
///
/// Android 12 (API 31) introduced the "Nearby devices" permissions, so the
/// request set depends on the OS version:
///
/// | Android   | Permissions requested                                  |
/// |-----------|--------------------------------------------------------|
/// | 12+ (31+) | BLUETOOTH_SCAN + BLUETOOTH_CONNECT                      |
/// | ≤ 11      | ACCESS_FINE_LOCATION (BLE scanning required location)   |
///
/// The manifest declares `BLUETOOTH_SCAN` with `neverForLocation`, so on
/// Android 12+ the location permission is intentionally *not* requested.
class PermissionService {
  PermissionService({DeviceInfoPlugin? deviceInfo}) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  static const int android12ApiLevel = 31;

  /// Best-effort Android API level. Defaults to 31 (modern flow) when the
  /// platform channel is unavailable, e.g. during widget tests.
  Future<int> androidSdkInt() async {
    try {
      final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
      return info.version.sdkInt;
    } on Exception catch (error) {
      debugPrint('device_info unavailable: $error');
      return android12ApiLevel;
    }
  }

  Future<bool> hasBlePermissions() async {
    try {
      final int sdk = await androidSdkInt();
      if (sdk >= android12ApiLevel) {
        final PermissionStatus scan = await Permission.bluetoothScan.status;
        final PermissionStatus connect = await Permission.bluetoothConnect.status;
        return scan.isGranted && connect.isGranted;
      }
      final PermissionStatus location = await Permission.locationWhenInUse.status;
      return location.isGranted;
    } on Exception catch (error) {
      debugPrint('permission check failed: $error');
      return false;
    }
  }

  Future<PermissionOutcome> requestBlePermissions() async {
    try {
      final int sdk = await androidSdkInt();
      if (sdk >= android12ApiLevel) {
        final Map<Permission, PermissionStatus> result = await <Permission>[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
        final Iterable<PermissionStatus> statuses = result.values;
        final bool granted = statuses.every(
          (PermissionStatus status) => status.isGranted || status.isLimited,
        );
        return PermissionOutcome(
          granted: granted,
          permanentlyDenied: statuses.any((PermissionStatus status) => status.isPermanentlyDenied),
          failure: granted ? null : 'BLUETOOTH_SCAN / BLUETOOTH_CONNECT not granted',
        );
      }

      final PermissionStatus location = await Permission.locationWhenInUse.request();
      return PermissionOutcome(
        granted: location.isGranted || location.isLimited,
        permanentlyDenied: location.isPermanentlyDenied,
        failure: location.isGranted ? null : 'ACCESS_FINE_LOCATION not granted',
      );
    } on MissingPluginException {
      // Widget tests / unsupported platforms: do not block the UI.
      return const PermissionOutcome(granted: true, permanentlyDenied: false);
    } on Exception catch (error) {
      return PermissionOutcome(
        granted: false,
        permanentlyDenied: false,
        failure: error.toString(),
      );
    }
  }

  Future<bool> openAppSettingsPage() async {
    try {
      return await openAppSettings();
    } on Exception catch (error) {
      debugPrint('openAppSettings failed: $error');
      return false;
    }
  }
}
