import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/ble_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/radar_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/models/ble_status.dart';
import '../navigation.dart';
import '../widgets/common/glow_button.dart';
import '../widgets/common/labels.dart';
import '../widgets/common/neon_card.dart';
import '../widgets/common/pulse_dot.dart';
import '../widgets/common/screen_header.dart';
import '../widgets/device/device_card.dart';
import '../widgets/device/device_filter_bar.dart';
import '../widgets/device/empty_state.dart';

/// Home screen: live device scanner with category filters.
class ScannerTab extends StatefulWidget {
  const ScannerTab({super.key});

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BleController ble = context.watch<BleController>();
    final SettingsController settings = context.watch<SettingsController>();
    final AppStrings strings = context.strings;
    final List<BleDevice> devices = ble.devices;
    final bool hasFilter = ble.kindFilter != null;

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: ScreenHeader(
              kicker: '${strings.liveFeed} · BLE',
              title: strings.appName,
              subtitle: strings.appSubtitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  NeonIconButton(
                    icon: _searchVisible ? Icons.close_rounded : Icons.search_rounded,
                    tooltip: strings.searchHint,
                    size: 38,
                    iconSize: 18,
                    onPressed: () {
                      setState(() {
                        _searchVisible = !_searchVisible;
                        if (!_searchVisible) {
                          _searchController.clear();
                          ble.setQuery('');
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  NeonIconButton(
                    icon: Icons.translate_rounded,
                    tooltip: settings.isArabic ? 'English' : 'العربية',
                    size: 38,
                    iconSize: 18,
                    filled: true,
                    onPressed: settings.toggleLanguage,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ScannerStatusCard(ble: ble, settings: settings),
          ),
          if (ble.errorMessage != null && !ble.status.needsGate) ...<Widget>[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ErrorBanner(message: ble.errorMessage!, onRetry: ble.rescan),
            ),
          ],
          const SizedBox(height: 12),
          DeviceFilterBar(
            selected: ble.kindFilter,
            counts: ble.kindCounts,
            total: ble.allDevices.length,
            onChanged: ble.setKindFilter,
          ),
          if (_searchVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _SearchField(
                controller: _searchController,
                hint: strings.searchHint,
                onChanged: ble.setQuery,
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              color: RadarColors.cyan,
              backgroundColor: RadarColors.surfaceHigh,
              onRefresh: ble.rescan,
              child: devices.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        ScannerEmptyState(
                          filtered: hasFilter || ble.query.isNotEmpty,
                          isMockMode: settings.mockMode,
                          onEnableDemo: () => ble.setMockMode(true),
                          onRefresh: ble.rescan,
                          onClearFilter: () {
                            ble.clearFilter();
                            ble.setQuery('');
                            _searchController.clear();
                          },
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
                      itemCount: devices.length + 1,
                      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == devices.length) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
                            child: Text(
                              strings.disclaimer,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.6,
                                color: RadarColors.textMuted.withValues(alpha: 0.8),
                              ),
                            ),
                          );
                        }
                        final BleDevice device = devices[index];
                        return DeviceCard(
                          device: device,
                          selected: ble.selectedId == device.id,
                          onTap: () => openDeviceRadar(context, device),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerStatusCard extends StatelessWidget {
  const _ScannerStatusCard({required this.ble, required this.settings});

  final BleController ble;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.strings;
    final bool demo = settings.mockMode;
    final bool scanning = ble.isScanning;
    final Color accent = demo ? RadarColors.purple : (scanning ? RadarColors.green : RadarColors.amber);
    final String status = demo
        ? strings.mockOn
        : ble.isPaused
            ? strings.paused
            : strings.scanning;

    return NeonCard(
      glowColor: accent,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
      borderColor: accent.withValues(alpha: 0.28),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              PulseDot(color: accent, size: 7, active: scanning),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            scanning ? strings.scanning : strings.paused,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.monoLabel(
                              size: 10,
                              color: accent,
                              letterSpacing: 2.2,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (demo) ...<Widget>[
                          const SizedBox(width: 8),
                          CodeBadge(label: strings.demoBadge, color: RadarColors.purple),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: RadarColors.textSecondary),
                    ),
                  ],
                ),
              ),
              NeonIconButton(
                icon: ble.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                tooltip: ble.isPaused ? strings.resumeScan : strings.pauseScan,
                size: 36,
                iconSize: 18,
                color: accent,
                filled: true,
                onPressed: ble.status.needsGate ? null : ble.togglePause,
              ),
              const SizedBox(width: 6),
              NeonIconButton(
                icon: Icons.refresh_rounded,
                tooltip: strings.refresh,
                size: 36,
                iconSize: 18,
                color: RadarColors.cyan,
                onPressed: ble.status.needsGate ? null : ble.rescan,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                strings.devicesInRange(ble.allDevices.length),
                style: AppTheme.monoLabel(
                  size: 9.5,
                  color: RadarColors.textMuted,
                  letterSpacing: 0.6,
                  weight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (ble.nearest != null)
                Text(
                  '${strings.nearestDevice} · '
                  '${Formatters.distanceWithUnit(ble.nearest!.distanceMeters, settings.units, arabic: settings.isArabic)}',
                  style: AppTheme.monoLabel(size: 9, color: ble.nearest!.zone.color, letterSpacing: 0.8),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: RadarColors.purple.withValues(alpha: 0.12),
                  border: Border.all(color: RadarColors.purple.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.science_rounded, size: 15, color: RadarColors.purple),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.mockModeTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RadarColors.textPrimary,
                      ),
                    ),
                    Text(
                      strings.mockModeSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.monoLabel(
                        size: 8.5,
                        color: RadarColors.textMuted,
                        letterSpacing: 0.1,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: demo,
                  onChanged: (bool value) {
                    ble.setMockMode(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint, required this.onChanged});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: RadarColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: RadarColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 13, color: RadarColors.textPrimary),
        cursorColor: RadarColors.cyan,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: RadarColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: RadarColors.textMuted),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RadarColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RadarColors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, size: 16, color: RadarColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: RadarColors.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          GlowButton(
            label: context.strings.retry,
            compact: true,
            height: 30,
            expand: false,
            variant: GlowButtonVariant.ghost,
            onPressed: () {
              onRetry();
            },
          ),
        ],
      ),
    );
  }
}
