import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'controllers/ble_controller.dart';
import 'controllers/settings_controller.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/radar_colors.dart';
import 'data/services/audio_service.dart';
import 'data/services/compass_service.dart';
import 'data/services/gatt_alert_service.dart';
import 'data/services/haptics_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/permission_gate_screen.dart';

/// Root widget: provider graph + MaterialApp configuration.
class BluetoothFinderRadarApp extends StatefulWidget {
  const BluetoothFinderRadarApp({
    super.key,
    required this.settings,
    required this.bleController,
    required this.audio,
    required this.haptics,
  });

  final SettingsController settings;
  final BleController bleController;
  final AudioService audio;
  final HapticsService haptics;

  @override
  State<BluetoothFinderRadarApp> createState() => _BluetoothFinderRadarAppState();
}

class _BluetoothFinderRadarAppState extends State<BluetoothFinderRadarApp> {
  final CompassService _compass = CompassService();
  final GattAlertService _alerts = const GattAlertService();

  @override
  void dispose() {
    unawaited(widget.audio.dispose());
    widget.bleController.dispose();
    _compass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: widget.settings),
        ChangeNotifierProvider<BleController>.value(value: widget.bleController),
        Provider<AudioService>.value(value: widget.audio),
        Provider<HapticsService>.value(value: widget.haptics),
        Provider<CompassService>.value(value: _compass),
        Provider<GattAlertService>.value(value: _alerts),
      ],
      child: Consumer<SettingsController>(
        builder: (BuildContext context, SettingsController settings, Widget? child) {
          return MaterialApp(
            title: settings.isArabic ? AppConstants.appNameAr : AppConstants.appNameEn,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (BuildContext context, Widget? appChild) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                  systemNavigationBarColor: RadarColors.background,
                  systemNavigationBarIconBrightness: Brightness.light,
                  systemNavigationBarDividerColor: Colors.transparent,
                ),
                child: appChild ?? const SizedBox.shrink(),
              );
            },
            home: const StartupGate(),
          );
        },
      ),
    );
  }
}

/// Decides between the permission/boot gate and the main shell.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      unawaited(context.read<BleController>().initialize());
    });
  }

  @override
  Widget build(BuildContext context) {
    final BleController ble = context.watch<BleController>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: ble.status.needsGate
          ? const PermissionGateScreen(key: ValueKey<String>('gate'))
          : const HomeScreen(key: ValueKey<String>('home')),
    );
  }
}
