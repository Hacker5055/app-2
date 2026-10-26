import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Outcome of a "play sound on the device" attempt.
enum GattAlertResult {
  /// The Alert Level characteristic accepted the write.
  sent,

  /// The device connected but exposes no Immediate Alert service — very common
  /// for earbuds, watches and proprietary trackers (AirTag/Tile use closed
  /// protocols that third-party apps cannot trigger).
  unsupported,

  /// Connection / permission / GATT failure.
  failed,
}

/// Writes Alert Level = High to the standard Bluetooth SIG **Immediate Alert
/// Service** (0x1802 → 0x2A06). Devices such as Galaxy SmartTags, Chipolo,
/// generic finder tags and many BLE speakers ring when they receive it.
class GattAlertService {
  const GattAlertService();

  static const String immediateAlertService = '1802';
  static const String alertLevelCharacteristic = '2a06';

  /// Alert Level values: 0 = No Alert, 1 = Mild Alert, 2 = High Alert.
  static const int highAlertLevel = 0x02;

  static bool _isUuid(Guid uuid, String shortUuid) {
    final String normalized = uuid.str.toLowerCase().replaceAll('-', '');
    final String short = shortUuid.toLowerCase().replaceAll('-', '');
    if (normalized == short) return true;
    if (short.length == 4) {
      return normalized.startsWith('0000$short');
    }
    return false;
  }

  static bool advertisesAlertService(Iterable<String> serviceUuids) {
    for (final String uuid in serviceUuids) {
      final String normalized = uuid.toLowerCase().replaceAll('-', '');
      if (normalized.startsWith('00001802')) return true;
    }
    return false;
  }

  static BluetoothCharacteristic? _findAlertLevel(List<BluetoothService> services) {
    for (final BluetoothService service in services) {
      if (!_isUuid(service.uuid, immediateAlertService)) continue;
      for (final BluetoothCharacteristic characteristic in service.characteristics) {
        if (_isUuid(characteristic.uuid, alertLevelCharacteristic)) {
          return characteristic;
        }
      }
    }
    // Some beacons put the Alert Level characteristic in a vendor service with
    // the standard characteristic UUID — search globally as a fallback.
    for (final BluetoothService service in services) {
      for (final BluetoothCharacteristic characteristic in service.characteristics) {
        if (_isUuid(characteristic.uuid, alertLevelCharacteristic)) return characteristic;
      }
    }
    return null;
  }

  Future<GattAlertResult> triggerAlert(
    String deviceId, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    BluetoothDevice? device;
    bool connectedHere = false;
    try {
      device = BluetoothDevice.fromId(deviceId);
      if (device.isDisconnected) {
        await device.connect(timeout: timeout);
        connectedHere = true;
      }

      final List<BluetoothService> services = await device.discoverServices();
      final BluetoothCharacteristic? alertCharacteristic = _findAlertLevel(services);
      if (alertCharacteristic == null) return GattAlertResult.unsupported;

      try {
        await alertCharacteristic.write(<int>[highAlertLevel]);
      } on Exception catch (error) {
        debugPrint('Alert write (with response) failed, retrying without: $error');
        await alertCharacteristic.write(<int>[highAlertLevel], withoutResponse: true);
      }
      return GattAlertResult.sent;
    } on Exception catch (error) {
      debugPrint('GATT alert failed for $deviceId: $error');
      return GattAlertResult.failed;
    } finally {
      if (connectedHere && device != null) {
        try {
          await device.disconnect();
        } on Exception catch (error) {
          debugPrint('GATT disconnect failed: $error');
        }
      }
    }
  }

  /// Checks whether the device exposes the Immediate Alert service without
  /// actually triggering it. Used to grey out the "Play sound" button.
  Future<bool?> supportsAlert(String deviceId, {Duration timeout = const Duration(seconds: 8)}) async {
    BluetoothDevice? device;
    bool connectedHere = false;
    try {
      device = BluetoothDevice.fromId(deviceId);
      if (device.isDisconnected) {
        await device.connect(timeout: timeout);
        connectedHere = true;
      }
      final List<BluetoothService> services = await device.discoverServices();
      return _findAlertLevel(services) != null;
    } on Exception catch (error) {
      debugPrint('GATT discovery failed for $deviceId: $error');
      return null;
    } finally {
      if (connectedHere && device != null) {
        try {
          await device.disconnect();
        } on Exception catch (error) {
          debugPrint('GATT disconnect failed: $error');
        }
      }
    }
  }
}
