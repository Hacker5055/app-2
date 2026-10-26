import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/ble_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/radar_colors.dart';
import '../../domain/models/ble_device.dart';
import '../widgets/common/app_background.dart';
import 'radar_tab.dart';
import 'scanner_tab.dart';
import 'settings_screen.dart';

/// Tab shell: Devices / Radar / Settings with a floating glass dock.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final BleController ble = context.watch<BleController>();
    final bool hasHot = ble.allDevices.any((BleDevice device) => device.zone.isHot);
    final int deviceCount = ble.allDevices.length;

    final List<Widget> tabs = <Widget>[
      const ScannerTab(),
      const RadarTab(),
      const SettingsScreen(),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            TickerMode(
              enabled: true,
              child: IndexedStack(
                index: _index,
                children: <Widget>[
                  for (int i = 0; i < tabs.length; i++)
                    TickerMode(enabled: _index == i, child: tabs[i]),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 10),
                child: _RadarNavBar(
                  index: _index,
                  deviceCount: deviceCount,
                  hasHotZone: hasHot,
                  onChanged: (int value) => setState(() => _index = value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarNavBar extends StatelessWidget {
  const _RadarNavBar({
    required this.index,
    required this.deviceCount,
    required this.hasHotZone,
    required this.onChanged,
  });

  final int index;
  final int deviceCount;
  final bool hasHotZone;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    return Container(
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xF2121724), Color(0xF2090C14)],
        ),
        border: Border.all(color: RadarColors.borderBright.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 24, offset: const Offset(0, 10)),
          BoxShadow(color: RadarColors.cyan.withValues(alpha: 0.06), blurRadius: 30),
        ],
      ),
      child: Row(
        children: <Widget>[
          _NavItem(
            label: strings.tabScan,
            icon: Icons.bluetooth_searching_rounded,
            active: index == 0,
            badge: deviceCount > 0 ? deviceCount : null,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            label: strings.tabRadar,
            icon: Icons.radar_rounded,
            active: index == 1,
            alert: hasHotZone,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            label: strings.tabSettings,
            icon: Icons.tune_rounded,
            active: index == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge,
    this.alert = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final int? badge;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? RadarColors.cyan : RadarColors.textMuted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      RadarColors.cyan.withValues(alpha: 0.17),
                      RadarColors.cyan.withValues(alpha: 0.04),
                    ],
                  )
                : null,
            border: Border.all(
              color: active ? RadarColors.cyan.withValues(alpha: 0.33) : Colors.transparent,
            ),
            boxShadow: active
                ? <BoxShadow>[BoxShadow(color: RadarColors.cyan.withValues(alpha: 0.14), blurRadius: 18)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Icon(icon, size: 20, color: color),
                  if (badge != null)
                    PositionedDirectional(
                      top: -5,
                      start: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: RadarColors.surfaceHighest,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: RadarColors.borderBright, width: 0.6),
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : '$badge',
                          style: AppTheme.monoLabel(
                            size: 7.5,
                            color: RadarColors.textSecondary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  if (alert)
                    PositionedDirectional(
                      top: -2,
                      start: 14,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: RadarColors.red,
                          boxShadow: <BoxShadow>[
                            BoxShadow(color: RadarColors.red.withValues(alpha: 0.8), blurRadius: 7),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 0.2,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
