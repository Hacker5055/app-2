# Architecture

Bluetooth Finder Radar is a single-activity Flutter app built in four layers. Each
layer only talks to the one below it, which keeps the BLE radio, the maths and the
pixels independently testable.

```text
┌──────────────────────────────────────────────────────────────────────┐
│ UI            screens · widgets · CustomPainters                     │
├──────────────────────────────────────────────────────────────────────┤
│ Controllers   BleController · DeviceTrackingController ·             │
│               SettingsController · SweepAssistantController          │
├──────────────────────────────────────────────────────────────────────┤
│ Data          BleRepository · scanner/permission/audio/haptics/...   │
├──────────────────────────────────────────────────────────────────────┤
│ Domain        models (pure data) · signal maths (pure functions)     │
└──────────────────────────────────────────────────────────────────────┘
```

## Bootstrapping

`lib/main.dart` constructs the object graph once and hands it to the widget tree:

```text
SharedPreferences ─► PreferencesService ─► SettingsController
AudioService (pre-loads the WAV samples)
BleRepository(real: FlutterBlueScannerService, mock: MockBleScannerService)
BleController(repository, settings, permissions)
HapticsService(enabled: settings.hapticsEnabled)
```

`BluetoothFinderRadarApp` exposes those instances through `provider` and renders
`PermissionGateScreen` or `HomeScreen` depending on `BleController.status`
(`BleSessionStatus.needsGate`). The compass and the GATT alert service are created by
the root state so they can be disposed with the app.

## Controllers

### `BleController` (ChangeNotifier)

The only writer of the device list.

* subscribes to `BleRepository` (real **and** mock scanners, filtered by mode),
* keeps a `_DevicePipeline` per device id:

  | field | purpose |
  | ----- | ------- |
  | `ema` | `ExponentialMovingAverage(α = 0.35)` over raw RSSI |
  | `smoothedRssi` | last filtered value (async alert service GATT callbacks) |
  | `history` | ring buffer of the last 48 smoothed samples |
  | `bearing` | stable pseudo-azimuth until the sweep locks a real one |
  | `firstSeen` / `lastSeen` | freshness + list ordering |
  | `txPower` / `pathLossExponent` | per-device calibration |
  | `alertService` | whether a GATT alert characteristic was found |

* recalculates distance with `PathLossCalculator` on every packet,
* emits a new immutable `List<BleDevice>` **once per second**
  (`AppConstants.uiRefreshInterval`) so widgets rebuild on a predictable cadence,
* drops devices that stopped advertising for 18 s, caps the list at 80 entries,
* exposes `latestSmoothedRssi(id)` for consumers that need the freshest filtered
  value without waiting for the next snapshot (sweep assistant),
* owns the permission/adapter state machine:

  ```text
  initializing → permissionRequired → scanning
               ↘ permissionDenied → permissionPermanentlyDenied
               ↘ adapterOff / adapterUnsupported / unauthorized
               ↘ error  (retry keeps the old list)
  ```

* starts a 10 s watchdog that restarts the scan if the OS silently killed it
  (screen off, adapter toggled, OEM battery manager). The scan itself is continuous;
  it is *not* restarted every few seconds, which would trip Android's scan throttling.

### `DeviceTrackingController`

Drives feedback for the open detail screen. A 50 ms scheduler interpolates nothing —
it simply checks whether enough time has elapsed for the next ping/haptic tick, where
the interval comes from `ProximityPulse` and the current distance:

```text
ping   : 130 ms … 1600 ms   (t^0.65 curve, 20 m scale)
haptic : 1.45 × ping        (never feels like a buzz saw)
volume : 0.18 … 0.73        (closer = louder, never full scale)
```

It pauses when the app leaves the foreground or the simulated screen turns off.

### `SettingsController`

Persisted preferences: mock mode, sound, haptics, units (metric/imperial), language
(AR/EN), TxPower, path-loss exponent, radar range, haptic/audio strength. Changing
TxPower or `n` re-computes every distance on the next snapshot without restarting the
scan.

### `SweepAssistantController`

Collects `(heading, smoothedRssi)` pairs at up to 20 Hz while the user rotates the
phone through 360°, then asks `AzimuthEstimator` for a weighted circular mean.
When the compass is unavailable (or mock mode is on) it synthesises a rotation so the
guided flow is still demonstrable.

## Data layer

| Service | Responsibility |
| ------- | -------------- |
| `FlutterBlueScannerService` | `flutter_blue_plus` 1.35.x: `startScan(continuousUpdates: true, continuousDivisor: 1, androidScanMode: lowLatency, androidCheckLocationServices: false)`, packet de-duplication by `(device, timestamp)`, adapter-state mapping, `stopScan`, `turnOn` |
| `MockBleScannerService` | deterministic 350 ms simulator, 8 devices, bounded random walk, Gaussian RSSI noise, Apple manufacturer frames |
| `PermissionService` | version-aware permission matrix (`BLUETOOTH_SCAN`/`CONNECT` on API 31+, location on ≤ 30), `openAppSettings`, adapter state |
| `AudioService` | two `AudioPlayer`s (ping + success), pre-loaded `AssetSource`s, release mode `stop`, volume by distance |
| `HapticsService` | `HapticFeedback` primitives with enable flag and rate limiting |
| `CompassService` | `flutter_compass` heading stream, median-of-three pre-filter, `isSupported` |
| `GattAlertService` | best-effort connect → find immediate-alert / Find My characteristic → write → disconnect, with timeouts |
| `PreferencesService` | typed wrapper around `SharedPreferences` |
| `DisplayService` | `MethodChannel('bluetooth_finder_radar/display')` → `FLAG_KEEP_SCREEN_ON` |

`BleRepository` owns both scanners and guarantees that only one runs at a time
(`activate(useMock:)` stops the other). This keeps the radio quiet in demo mode and
prevents duplicated device lists.

## Domain layer

Nothing here imports Flutter widgets, which is why the maths is unit-testable:

* `PathLossCalculator` — forward and inverse log-distance model, calibration, clamps.
* `ExponentialMovingAverage` — EMA with α guard rails; `MedianOfThree` for headings;
  `circularMedian` for angles.
* `AzimuthEstimator` — weighted circular mean, confidence, coverage.
* `ProximityPulse` — continuous Geiger cadence, intensity, volume.
* `ProximityZone` — the four spec zones, colours, cadence and glow strength.
* `BleDevice` — immutable UI snapshot plus list extensions
  (`sortedByDistance`, `sortedBySignal`, `nearest`, `maxDistance`).
* `DeviceClassifier` — name/manufacturer/service heuristics for
  Earbuds / Watches / Trackers / Unknown.

## UI layer

* Every screen is a `Scaffold(backgroundColor: Colors.transparent)` on top of
  `AppBackground` (radial gradient + subtle grid + vignette), so the ultra-dark
  `#08090E` canvas is continuous across navigations.
* The radar is a stack of `CustomPainter`s (`RadarGridPainter`,
  `RadarSweepPainter`, `RadarPulsePainter`, `RadarBearingPainter`) driven by a single
  `AnimationController`; device nodes are `AnimatedPositioned` widgets on top, so
  labels stay selectable and hit-testable.
* Node positions come from `BleDevice.radarRadiusFraction(maxRangeMeters)` (r ∝ d)
  and the device bearing; distance is never rendered as raw pixels, which keeps the
  layout correct at any screen size.
* All text goes through `AppStrings`; numerals stay monospace in both languages.

## Threading & lifecycle

* Flutter is single-threaded; the BLE plugin delivers packets on the platform thread
  into a Dart `Stream`.
* The controller batches: packets update the pipeline immediately, the UI snapshot is
  published on a 1 s `Timer.periodic` (no per-packet `notifyListeners`, so 30+ devices
  do not melt the frame budget).
* `WidgetsBindingObserver` pauses tracking/feedback when the app is backgrounded.
* `dispose()` order: radar screen → tracking → confetti; app → audio, controllers,
  compass. All subscriptions and timers are cancelled.

## Why these choices

| Decision | Reason |
| -------- | ------ |
| `flutter_blue_plus` | mature Android support, 1 s+ continuous scan updates, access to manufacturer data needed for AirPods/Tile/AirTag classification |
| `provider` | small, explicit, no code generation; the graph is created once in `main` |
| No database | a lost-device session is short-lived; 48 samples per device is enough for the sparkline |
| Mock scanner shares the domain maths | demo mode exercises the real smoothing/zoning code instead of faking UI values |
