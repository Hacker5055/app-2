import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/ble_controller.dart';
import '../domain/models/ble_device.dart';
import 'screens/device_radar_screen.dart';

/// Selects [device] and opens its dedicated radar screen.
Future<void> openDeviceRadar(BuildContext context, BleDevice device) async {
  final BleController ble = context.read<BleController>();
  ble.selectDevice(device.id);
  HapticFeedback.lightImpact();
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => DeviceRadarScreen(
        deviceId: device.id,
        initialDevice: device,
      ),
    ),
  );
}
