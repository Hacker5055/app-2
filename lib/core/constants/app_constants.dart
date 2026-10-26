/// Central place for every tunable value of the BLE proximity pipeline.
///
/// Keeping the numbers here (instead of scattering them across widgets) makes
/// the signal-processing behaviour auditable and unit-testable.
class AppConstants {
  const AppConstants._();

  // ---------------------------------------------------------------------------
  // Branding
  // ---------------------------------------------------------------------------
  static const String appNameEn = 'Bluetooth Finder Radar';
  static const String appNameAr = 'رادار الأجهزة المفقودة';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // ---------------------------------------------------------------------------
  // Path-loss model
  //
  //     distance = 10 ^ ((TxPower - RSSI) / (10 * n))
  //
  // TxPower is the expected RSSI at exactly one metre from the transmitter,
  // n is the environmental path-loss exponent (2.0 = free space,
  // 2.5 = typical indoor room, 3.0+ = walls / furniture).
  // ---------------------------------------------------------------------------
  static const double defaultTxPower = -59.0;
  static const double defaultPathLossExponent = 2.5;
  static const double minTxPower = -90.0;
  static const double maxTxPower = -35.0;
  static const double minPathLossExponent = 1.5;
  static const double maxPathLossExponent = 4.5;

  // ---------------------------------------------------------------------------
  // Exponential Moving Average smoothing
  //
  // smoothed = alpha * raw + (1 - alpha) * previousSmoothed
  // A lower alpha = calmer bars but slower reactions.
  // ---------------------------------------------------------------------------
  static const double defaultEmaAlpha = 0.35;

  /// Hard bounds for the estimated distance (metres). RSSI readings outside
  /// these limits are physically meaningless and would break the radar scale.
  static const double minDistanceMeters = 0.05;
  static const double maxDistanceMeters = 200.0;
  static const double minEmaAlpha = 0.1;
  static const double maxEmaAlpha = 0.9;

  // ---------------------------------------------------------------------------
  // Proximity zones (metres)
  // ---------------------------------------------------------------------------
  static const double hotZoneMeters = 1.0;
  static const double warmZoneMeters = 3.0;
  static const double moderateZoneMeters = 10.0;

  // ---------------------------------------------------------------------------
  // Scanner / UI timing
  // ---------------------------------------------------------------------------
  /// The UI is refreshed exactly once per second (spec requirement) while the
  /// BLE stack keeps feeding packets into the smoothing filter continuously.
  static const Duration uiRefreshInterval = Duration(seconds: 1);

  /// How often the scanner checks that the radio is still scanning (e.g. after
  /// the adapter was toggled or the OS killed the scan). Scanning itself is
  /// continuous — restarting every few seconds would trip Android's scan
  /// throttling instead of avoiding it.
  static const Duration scanWatchdogInterval = Duration(seconds: 10);

  /// Devices that stopped advertising for this long are removed from the radar.
  static const Duration deviceStaleTimeout = Duration(seconds: 18);

  /// Radar sweep rotation period.
  static const Duration radarSweepPeriod = Duration(seconds: 4);

  /// Pulse animation for the sonar rings.
  static const Duration radarPulsePeriod = Duration(milliseconds: 2600);

  /// Geiger-counter cadence: interval (ms) at d ≈ 0 → "hot" end.
  static const int geigerFastestIntervalMs = 130;

  /// Geiger-counter cadence at the far end of the radar.
  static const int geigerSlowestIntervalMs = 1600;

  static const int maxSignalHistory = 48;
  static const int maxDevices = 80;
  static const double feetPerMeter = 3.280839895;

  // ---------------------------------------------------------------------------
  // Radar rendering
  // ---------------------------------------------------------------------------
  static const double defaultRadarRangeMeters = 20.0;
  static const double minRadarRangeMeters = 5.0;
  static const double maxRadarRangeMeters = 50.0;
  static const int radarRingCount = 4;
  static const int radarTickCount = 72;

  /// Nodes never sit exactly on the centre so that "0.1 m" is still visible.
  static const double radarInnerRadiusFraction = 0.055;

  static const List<double> pathLossExponentPresets = <double>[2.0, 2.5, 3.0];
}
