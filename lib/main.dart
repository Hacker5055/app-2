import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/ble_controller.dart';
import 'controllers/settings_controller.dart';
import 'data/repositories/ble_repository.dart';
import 'data/services/audio_service.dart';
import 'data/services/flutter_blue_scanner_service.dart';
import 'data/services/haptics_service.dart';
import 'data/services/mock_ble_scanner_service.dart';
import 'data/services/permission_service.dart';
import 'data/services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  final SettingsController settings = SettingsController(
    PreferencesService(sharedPreferences),
  );
  settings.load(systemLanguageCode: PlatformDispatcher.instance.locale.languageCode);

  final AudioService audio = AudioService();
  await audio.initialize();

  final HapticsService haptics = HapticsService(enabled: settings.hapticsEnabled);

  final BleRepository repository = BleRepository(
    realScanner: FlutterBlueScannerService(),
    mockScanner: MockBleScannerService(),
  );

  final BleController bleController = BleController(
    repository: repository,
    settings: settings,
    permissions: PermissionService(),
  );

  runApp(
    BluetoothFinderRadarApp(
      settings: settings,
      bleController: bleController,
      audio: audio,
      haptics: haptics,
    ),
  );
}
