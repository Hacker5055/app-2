import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the screen awake while a device is being tracked.
///
/// Implemented by the host activity (`com.arena.bluetoothfinderradar.MainActivity`)
/// so the app does not need a third-party wakelock plugin. The call is
/// best-effort: on platforms/tests where the channel is missing it silently
/// does nothing.
class DisplayService {
  const DisplayService();

  static const MethodChannel _channel = MethodChannel('bluetooth_finder_radar/display');

  Future<void> setKeepScreenOn({required bool enabled}) async {
    try {
      await _channel.invokeMethod<bool>('keepScreenOn', <String, dynamic>{'enabled': enabled});
    } on MissingPluginException {
      // Widget tests / unsupported platforms.
    } on PlatformException catch (error) {
      debugPrint('DisplayService: keepScreenOn failed (${error.code})');
    }
  }
}
