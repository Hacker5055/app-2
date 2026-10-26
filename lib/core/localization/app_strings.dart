import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../domain/models/device_kind.dart';
import '../../domain/models/proximity_zone.dart';

/// Hand-written, strongly typed localization layer.
///
/// Why not ARB codegen? The app ships exactly two locales and every string is
/// compile-time checked here: if a translation is missing, the analyzer fails.
/// No build step, no synthetic packages, no runtime lookup misses.
abstract class AppStrings {
  const AppStrings();

  // Branding ------------------------------------------------------------------
  String get appName;
  String get appSubtitle;
  String get tabScan;
  String get tabRadar;
  String get tabSettings;

  // Scanner -------------------------------------------------------------------
  String get scanning;
  String get paused;
  String devicesInRange(int count);
  String get filterAll;
  String get filterEarbuds;
  String get filterWatches;
  String get filterTrackers;
  String get filterUnknown;
  String get searchHint;
  String get unknownDevice;
  String get demoBadge;
  String get liveBadge;
  String get mockModeTitle;
  String get mockModeSubtitle;
  String get mockOn;
  String get mockOff;
  String get pauseScan;
  String get resumeScan;
  String get refresh;
  String get nearestDevice;
  String get scanError;
  String get emptyTitle;
  String get emptyBody;
  String get emptyFilterTitle;
  String get emptyFilterBody;
  String get clearFilter;
  String get signalLabel;
  String get distanceLabel;
  String get lastSeenLabel;
  String get now;
  String secondsAgo(int seconds);
  String minutesAgo(int minutes);
  String get deviceIdLabel;
  String get connectable;
  String get broadcastOnly;
  String get devicesFoundLabel;
  String get sortNearest;
  String get sortSignal;

  // Permissions / adapter -----------------------------------------------------
  String get initTitle;
  String get initBody;
  String get permissionTitle;
  String get permissionBody;
  String get permissionScan;
  String get permissionConnect;
  String get permissionLocation;
  String get permissionOptional;
  String get grantPermissions;
  String get permissionDenied;
  String get permissionPermanentlyDenied;
  String get openSettings;
  String get continueDemo;
  String get skipForNow;
  String get bluetoothOffTitle;
  String get bluetoothOffBody;
  String get turnOnBluetooth;
  String get bluetoothUnsupportedTitle;
  String get bluetoothUnsupportedBody;
  String get unauthorizedTitle;
  String get unauthorizedBody;
  String get retry;

  // Radar ---------------------------------------------------------------------
  String get radarTitle;
  String get radarSubtitle;
  String get radarLegendHint;
  String get bearingsNote;
  String get noSelectionTitle;
  String get noSelectionBody;
  String get viewScanner;
  String get scanningHint;
  String get selectTargetTitle;
  String get selectTargetBody;
  String get rangeLabel;
  String get radarCenter;

  // Device detail -------------------------------------------------------------
  String get deviceRadarTitle;
  String get trackingLabel;
  String get metersAway;
  String get feetAway;
  String distanceReadout(String value, String unit);
  String get zoneHintHot;
  String get zoneHintWarm;
  String get zoneHintModerate;
  String get zoneHintCold;
  String get signalStrength;
  String get rawRssi;
  String get smoothedRssi;
  String get playSound;
  String get playSoundHint;
  String get alertSent;
  String get alertUnsupported;
  String get alertFailed;
  String get markFound;
  String get foundTitle;
  String foundBody(String name);
  String get backToDevices;
  String get keepTracking;
  String get geigerActive;
  String get geigerMuted;
  String get history;
  String get liveFeed;
  String get deviceDetails;

  // Sweep assistant -----------------------------------------------------------
  String get sweepAssistant;
  String get sweepTitle;
  String get sweepIntro;
  String get sweepStart;
  String get sweepProgress;
  String sweepDegreesLeft(int degrees);
  String get sweepComplete;
  String get sweepPeakHeading;
  String get sweepConfidence;
  String get sweepLock;
  String get sweepAgain;
  String get sweepSimulated;
  String get sweepNoCompass;
  String get compassUnavailable;
  String get swipeHint;
  String get close;
  String get cancel;
  String get north;
  String get south;
  String get east;
  String get west;
  String headingDegrees(int degrees);

  // Settings ------------------------------------------------------------------
  String get settingsTitle;
  String get sectionAppearance;
  String get sectionSignal;
  String get sectionScanning;
  String get sectionAlerts;
  String get sectionAbout;
  String get language;
  String get languageArabic;
  String get languageEnglish;
  String get units;
  String get unitsMetric;
  String get unitsImperial;
  String get soundAlerts;
  String get hapticAlerts;
  String get mockData;
  String get mockDataHint;
  String get emaAlpha;
  String get emaAlphaHint;
  String get pathLoss;
  String get pathLossHint;
  String get txPower;
  String get txPowerHint;
  String get radarRange;
  String get radarRangeHint;
  String get calibrate;
  String get calibrateHint;
  String calibrated(String value);
  String get calibrateFailed;
  String get resetDefaults;
  String get resetConfirmTitle;
  String get resetConfirmBody;
  String get reset;
  String get aboutBody;
  String version(String version);
  String get permissionsInfo;
  String get permissionListBody;
  String get disclaimer;
  String get settingsSaved;

  String get yes;
  String get no;
  String get notAvailable;
  String get signalLostTitle;
  String get signalLostBody;
  String get scanAgain;
  String get pulseInterval;
  String get alertService;
  String get advertisedTxPower;
  String get bearingLocked;
  String get foundBadge;

  // Shared --------------------------------------------------------------------
  String zoneLabel(ProximityZone zone);
  String zoneRange(ProximityZone zone);
  String zoneHint(ProximityZone zone);
  String kindLabel(DeviceKind kind);
  String get done;
}

class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  String get appName => 'Bluetooth Finder Radar';
  @override
  String get appSubtitle => 'BLE proximity radar';
  @override
  String get tabScan => 'Devices';
  @override
  String get tabRadar => 'Radar';
  @override
  String get tabSettings => 'Settings';

  @override
  String get scanning => 'SCANNING';
  @override
  String get paused => 'PAUSED';
  @override
  String devicesInRange(int count) => count == 1 ? '1 device in range' : '$count devices in range';
  @override
  String get filterAll => 'All';
  @override
  String get filterEarbuds => 'Earbuds';
  @override
  String get filterWatches => 'Watches';
  @override
  String get filterTrackers => 'Trackers';
  @override
  String get filterUnknown => 'Unknown';
  @override
  String get searchHint => 'Search name or MAC…';
  @override
  String get unknownDevice => 'Unnamed BLE device';
  @override
  String get demoBadge => 'DEMO';
  @override
  String get liveBadge => 'LIVE';
  @override
  String get mockModeTitle => 'Mock BLE data';
  @override
  String get mockModeSubtitle => 'Simulate nearby devices inside an emulator';
  @override
  String get mockOn => 'Demo mode on — synthetic beacons';
  @override
  String get mockOff => 'Live BLE scanning';
  @override
  String get pauseScan => 'Pause scan';
  @override
  String get resumeScan => 'Resume scan';
  @override
  String get refresh => 'Refresh';
  @override
  String get nearestDevice => 'NEAREST';
  @override
  String get scanError => 'Scan error';
  @override
  String get emptyTitle => 'No devices in range yet';
  @override
  String get emptyBody =>
      'Bring the device closer, or switch on demo mode to explore the radar without Bluetooth hardware.';
  @override
  String get emptyFilterTitle => 'Nothing matches this filter';
  @override
  String get emptyFilterBody => 'Try another category or clear the filter.';
  @override
  String get clearFilter => 'Clear filter';
  @override
  String get signalLabel => 'SIGNAL';
  @override
  String get distanceLabel => 'DISTANCE';
  @override
  String get lastSeenLabel => 'LAST SEEN';
  @override
  String get now => 'now';
  @override
  String secondsAgo(int seconds) => '${seconds}s ago';
  @override
  String minutesAgo(int minutes) => '${minutes}m ago';
  @override
  String get deviceIdLabel => 'MAC / UUID';
  @override
  String get connectable => 'Connectable';
  @override
  String get broadcastOnly => 'Broadcast only';
  @override
  String get devicesFoundLabel => 'DEVICES';
  @override
  String get sortNearest => 'Nearest';
  @override
  String get sortSignal => 'Signal';

  @override
  String get initTitle => 'Initialising BLE radar';
  @override
  String get initBody => 'Warming up the Bluetooth stack and smoothing filters…';
  @override
  String get permissionTitle => 'Radar needs Bluetooth access';
  @override
  String get permissionBody => 'To find nearby BLE devices the radar requires:';
  @override
  String get permissionScan => 'Nearby device scanning (BLUETOOTH_SCAN)';
  @override
  String get permissionConnect => 'Connect & trigger alerts (BLUETOOTH_CONNECT)';
  @override
  String get permissionLocation => 'Location for Android 11 and below';
  @override
  String get permissionOptional => 'optional on Android 12+';
  @override
  String get grantPermissions => 'Grant permissions';
  @override
  String get permissionDenied => 'Permission denied. You can still explore demo mode.';
  @override
  String get permissionPermanentlyDenied =>
      'Permissions are blocked permanently. Enable them from the app settings.';
  @override
  String get openSettings => 'Open settings';
  @override
  String get continueDemo => 'Continue without Bluetooth';
  @override
  String get skipForNow => 'Skip for now';
  @override
  String get bluetoothOffTitle => 'Bluetooth is off';
  @override
  String get bluetoothOffBody => 'Turn on Bluetooth to start scanning for nearby devices.';
  @override
  String get turnOnBluetooth => 'Turn on Bluetooth';
  @override
  String get bluetoothUnsupportedTitle => 'Bluetooth is unavailable';
  @override
  String get bluetoothUnsupportedBody =>
      'This device does not report BLE support. Demo mode still works.';
  @override
  String get unauthorizedTitle => 'Bluetooth access blocked';
  @override
  String get unauthorizedBody => 'Allow Bluetooth access for this app in the system settings.';
  @override
  String get retry => 'Retry';

  @override
  String get radarTitle => 'Proximity radar';
  @override
  String get radarSubtitle => 'Nodes are placed by estimated distance';
  @override
  String get radarLegendHint => 'Distance from the centre = estimated metres';
  @override
  String get bearingsNote =>
      'Bearings are refined by the 360° sweep. Until then each device uses a stable placeholder angle.';
  @override
  String get noSelectionTitle => 'Radar is idle';
  @override
  String get noSelectionBody => 'Select a device from the scanner to start the hunt.';
  @override
  String get viewScanner => 'Open scanner';
  @override
  String get scanningHint => 'Sweeping nearby BLE channels…';
  @override
  String get selectTargetTitle => 'Pick a target';
  @override
  String get selectTargetBody => 'Choose a device to open its dedicated radar.';
  @override
  String get rangeLabel => 'RANGE';
  @override
  String get radarCenter => 'YOU';

  @override
  String get deviceRadarTitle => 'Device radar';
  @override
  String get trackingLabel => 'TRACKING';
  @override
  String get metersAway => 'meters away';
  @override
  String get feetAway => 'feet away';
  @override
  String distanceReadout(String value, String unit) => '$value $unit away';
  @override
  String get zoneHintHot => 'You are on top of it — follow the rapid ticks.';
  @override
  String get zoneHintWarm => 'Very close. Sweep slowly to pinpoint the direction.';
  @override
  String get zoneHintModerate => 'Getting warmer — keep moving and watch the signal.';
  @override
  String get zoneHintCold => 'Far away. Walk around and listen for faster ticks.';
  @override
  String get signalStrength => 'Signal strength';
  @override
  String get rawRssi => 'RAW';
  @override
  String get smoothedRssi => 'SMOOTHED';
  @override
  String get playSound => 'Play sound';
  @override
  String get playSoundHint => 'Writes Alert Level to the device\'s Immediate Alert service';
  @override
  String get alertSent => 'Alert command sent';
  @override
  String get alertUnsupported => 'This device does not expose a GATT alert service';
  @override
  String get alertFailed => 'Could not reach the device — it may not accept connections';
  @override
  String get markFound => 'Mark as found';
  @override
  String get foundTitle => 'Target located!';
  @override
  String foundBody(String name) => '$name is marked as found. Great hunting, operator.';
  @override
  String get backToDevices => 'Back to devices';
  @override
  String get keepTracking => 'Keep tracking';
  @override
  String get geigerActive => 'Geiger ticks active';
  @override
  String get geigerMuted => 'Geiger ticks muted';
  @override
  String get history => 'RSSI history';
  @override
  String get liveFeed => 'Live feed';
  @override
  String get deviceDetails => 'Signal diagnostics';

  @override
  String get sweepAssistant => '360° sweep';
  @override
  String get sweepTitle => 'Direction finder';
  @override
  String get sweepIntro =>
      'Hold the phone flat and rotate slowly through a full circle. The radar records signal strength at every heading.';
  @override
  String get sweepStart => 'Start sweep';
  @override
  String get sweepProgress => 'Sweep progress';
  @override
  String sweepDegreesLeft(int degrees) => '$degrees° to go';
  @override
  String get sweepComplete => 'Sweep complete';
  @override
  String get sweepPeakHeading => 'Strongest heading';
  @override
  String get sweepConfidence => 'Confidence';
  @override
  String get sweepLock => 'Lock bearing on radar';
  @override
  String get sweepAgain => 'Sweep again';
  @override
  String get sweepSimulated => 'Demo mode — simulated rotation';
  @override
  String get sweepNoCompass => 'No magnetometer detected — using simulated rotation.';
  @override
  String get compassUnavailable => 'Compass unavailable';
  @override
  String get swipeHint => 'Swipe down to dismiss';
  @override
  String get close => 'Close';
  @override
  String get cancel => 'Cancel';
  @override
  String get north => 'N';
  @override
  String get south => 'S';
  @override
  String get east => 'E';
  @override
  String get west => 'W';
  @override
  String headingDegrees(int degrees) => '$degrees°';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get sectionAppearance => 'APPEARANCE';
  @override
  String get sectionSignal => 'SIGNAL PROCESSING';
  @override
  String get sectionScanning => 'SCANNING';
  @override
  String get sectionAlerts => 'ALERTS';
  @override
  String get sectionAbout => 'ABOUT';
  @override
  String get language => 'Language';
  @override
  String get languageArabic => 'العربية';
  @override
  String get languageEnglish => 'English';
  @override
  String get units => 'Distance units';
  @override
  String get unitsMetric => 'Meters';
  @override
  String get unitsImperial => 'Feet';
  @override
  String get soundAlerts => 'Sound pings';
  @override
  String get hapticAlerts => 'Haptic ticks';
  @override
  String get mockData => 'Mock BLE data';
  @override
  String get mockDataHint => 'Generate synthetic beacons — perfect for emulators';
  @override
  String get emaAlpha => 'EMA smoothing';
  @override
  String get emaAlphaHint => 'Lower is calmer, higher reacts faster';
  @override
  String get pathLoss => 'Path-loss exponent (n)';
  @override
  String get pathLossHint => '2.0 free space · 2.5 indoors · 3.0+ obstacles';
  @override
  String get txPower => 'TxPower at 1 m';
  @override
  String get txPowerHint => 'Expected RSSI one metre from the transmitter';
  @override
  String get radarRange => 'Radar range';
  @override
  String get radarRangeHint => 'Outer ring of the radar viewport';
  @override
  String get calibrate => 'Calibrate at 1 m';
  @override
  String get calibrateHint => 'Stand one metre from the device, then tap to learn its TxPower.';
  @override
  String calibrated(String value) => 'Calibrated — TxPower is now $value dBm';
  @override
  String get calibrateFailed => 'No live device to calibrate against';
  @override
  String get resetDefaults => 'Reset to defaults';
  @override
  String get resetConfirmTitle => 'Reset settings?';
  @override
  String get resetConfirmBody => 'TxPower, n, EMA and display options return to their defaults.';
  @override
  String get reset => 'Reset';
  @override
  String get aboutBody =>
      'A Flutter BLE radar that estimates distance from RSSI with the log-distance path-loss model, then smooths every reading with an exponential moving average.';
  @override
  String version(String version) => 'Version $version';
  @override
  String get permissionsInfo => 'Permissions';
  @override
  String get permissionListBody =>
      'BLUETOOTH_SCAN (neverForLocation) · BLUETOOTH_CONNECT · ACCESS_FINE_LOCATION (Android ≤ 11)';
  @override
  String get disclaimer =>
      'RSSI-based distance is an estimate: walls, bodies and antenna orientation change the reading.';
  @override
  String get settingsSaved => 'Saved';

  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';
  @override
  String get notAvailable => '—';
  @override
  String get signalLostTitle => 'Signal lost';
  @override
  String get signalLostBody => 'This device stopped advertising. Move closer or rescan.';
  @override
  String get scanAgain => 'Scan again';
  @override
  String get pulseInterval => 'PULSE';
  @override
  String get alertService => 'ALERT SERVICE';
  @override
  String get advertisedTxPower => 'ADVERTISED TX';
  @override
  String get bearingLocked => 'Bearing locked onto the radar';
  @override
  String get foundBadge => 'FOUND';

  @override
  String zoneLabel(ProximityZone zone) => zone.labelEn;
  @override
  String zoneRange(ProximityZone zone) => zone.rangeEn;
  @override
  String zoneHint(ProximityZone zone) => switch (zone) {
        ProximityZone.hot => zoneHintHot,
        ProximityZone.warm => zoneHintWarm,
        ProximityZone.moderate => zoneHintModerate,
        ProximityZone.cold => zoneHintCold,
      };
  @override
  String kindLabel(DeviceKind kind) => kind.labelEn;
  @override
  String get done => 'Done';
}

class AppStringsAr extends AppStrings {
  const AppStringsAr();

  @override
  String get appName => 'رادار الأجهزة المفقودة';
  @override
  String get appSubtitle => 'رادار البلوتوث القريب';
  @override
  String get tabScan => 'الأجهزة';
  @override
  String get tabRadar => 'الرادار';
  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get scanning => 'جارٍ المسح';
  @override
  String get paused => 'متوقف مؤقتًا';
  @override
  String devicesInRange(int count) {
    if (count == 0) return 'لا توجد أجهزة قريبة';
    if (count == 1) return 'جهاز واحد قريب';
    if (count == 2) return 'جهازان قريبان';
    if (count <= 10) return '$count أجهزة قريبة';
    return '$count جهازًا قريبًا';
  }

  @override
  String get filterAll => 'الكل';
  @override
  String get filterEarbuds => 'سماعات';
  @override
  String get filterWatches => 'ساعات';
  @override
  String get filterTrackers => 'متعقبات';
  @override
  String get filterUnknown => 'غير معروف';
  @override
  String get searchHint => 'ابحث بالاسم أو عنوان MAC…';
  @override
  String get unknownDevice => 'جهاز بلوتوث بدون اسم';
  @override
  String get demoBadge => 'تجريبي';
  @override
  String get liveBadge => 'مباشر';
  @override
  String get mockModeTitle => 'بيانات بلوتوث وهمية';
  @override
  String get mockModeSubtitle => 'محاكاة أجهزة قريبة داخل المحاكي';
  @override
  String get mockOn => 'الوضع التجريبي مفعّل — إشارات وهمية';
  @override
  String get mockOff => 'مسح بلوتوث حقيقي';
  @override
  String get pauseScan => 'إيقاف المسح';
  @override
  String get resumeScan => 'استئناف المسح';
  @override
  String get refresh => 'تحديث';
  @override
  String get nearestDevice => 'الأقرب';
  @override
  String get scanError => 'خطأ في المسح';
  @override
  String get emptyTitle => 'لا توجد أجهزة في المدى بعد';
  @override
  String get emptyBody => 'قرّب الجهاز من هاتفك، أو فعّل الوضع التجريبي لاستكشاف الرادار دون بلوتوث.';
  @override
  String get emptyFilterTitle => 'لا نتائج لهذا الفلتر';
  @override
  String get emptyFilterBody => 'جرّب فئة أخرى أو امسح الفلتر.';
  @override
  String get clearFilter => 'مسح الفلتر';
  @override
  String get signalLabel => 'الإشارة';
  @override
  String get distanceLabel => 'المسافة';
  @override
  String get lastSeenLabel => 'آخر ظهور';
  @override
  String get now => 'الآن';
  @override
  String secondsAgo(int seconds) => 'منذ $seconds ث';
  @override
  String minutesAgo(int minutes) => 'منذ $minutes د';
  @override
  String get deviceIdLabel => 'العنوان / المعرّف';
  @override
  String get connectable => 'قابل للاتصال';
  @override
  String get broadcastOnly => 'بث فقط';
  @override
  String get devicesFoundLabel => 'الأجهزة';
  @override
  String get sortNearest => 'الأقرب';
  @override
  String get sortSignal => 'الإشارة';

  @override
  String get initTitle => 'جارٍ تهيئة رادار البلوتوث';
  @override
  String get initBody => 'يتم تشغيل البلوتوث ومرشحات تنعيم الإشارة…';
  @override
  String get permissionTitle => 'يحتاج الرادار إلى إذن البلوتوث';
  @override
  String get permissionBody => 'للبحث عن أجهزة البلوتوث القريبة يحتاج التطبيق إلى:';
  @override
  String get permissionScan => 'مسح الأجهزة القريبة (BLUETOOTH_SCAN)';
  @override
  String get permissionConnect => 'الاتصال وإطلاق التنبيهات (BLUETOOTH_CONNECT)';
  @override
  String get permissionLocation => 'الموقع لأندرويد 11 وما قبله';
  @override
  String get permissionOptional => 'اختياري على أندرويد 12+';
  @override
  String get grantPermissions => 'منح الأذونات';
  @override
  String get permissionDenied => 'تم رفض الإذن. يمكنك تجربة الوضع التجريبي.';
  @override
  String get permissionPermanentlyDenied => 'الأذونات محظورة نهائيًا. فعّلها من إعدادات التطبيق.';
  @override
  String get openSettings => 'فتح الإعدادات';
  @override
  String get continueDemo => 'المتابعة بدون بلوتوث';
  @override
  String get skipForNow => 'تخطٍ الآن';
  @override
  String get bluetoothOffTitle => 'البلوتوث مغلق';
  @override
  String get bluetoothOffBody => 'شغّل البلوتوث لبدء البحث عن الأجهزة القريبة.';
  @override
  String get turnOnBluetooth => 'تشغيل البلوتوث';
  @override
  String get bluetoothUnsupportedTitle => 'البلوتوث غير متوفر';
  @override
  String get bluetoothUnsupportedBody => 'هذا الجهاز لا يدعم البلوتوث منخفض الطاقة. الوضع التجريبي يعمل.';
  @override
  String get unauthorizedTitle => 'الوصول للبلوتوث محظور';
  @override
  String get unauthorizedBody => 'اسمح بالوصول للبلوتوث لهذا التطبيق من إعدادات النظام.';
  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get radarTitle => 'رادار القرب';
  @override
  String get radarSubtitle => 'تُوضع النقاط حسب المسافة المقدّرة';
  @override
  String get radarLegendHint => 'البعد عن المركز = المسافة المقدّرة بالأمتار';
  @override
  String get bearingsNote => 'يُحسّن المسح ٣٦٠° دقة الاتجاه. قبل ذلك تُستخدم زاوية ثابتة لكل جهاز.';
  @override
  String get noSelectionTitle => 'الرادار في وضع الانتظار';
  @override
  String get noSelectionBody => 'اختر جهازًا من الماسح لبدء البحث.';
  @override
  String get viewScanner => 'فتح الماسح';
  @override
  String get scanningHint => 'جارٍ مسح قنوات البلوتوث القريبة…';
  @override
  String get selectTargetTitle => 'اختر هدفًا';
  @override
  String get selectTargetBody => 'اختر جهازًا لفتح راداره الخاص.';
  @override
  String get rangeLabel => 'المدى';
  @override
  String get radarCenter => 'أنت';

  @override
  String get deviceRadarTitle => 'رادار الجهاز';
  @override
  String get trackingLabel => 'تتبّع';
  @override
  String get metersAway => 'مترًا';
  @override
  String get feetAway => 'قدمًا';
  @override
  String distanceReadout(String value, String unit) => 'يبعد $value $unit';
  @override
  String get zoneHintHot => 'أنت فوقه تقريبًا — تابع النبضات السريعة.';
  @override
  String get zoneHintWarm => 'قريب جدًا. حرّك الهاتف ببطء لتحديد الاتجاه.';
  @override
  String get zoneHintModerate => 'تقترب — استمر في الحركة وراقب الإشارة.';
  @override
  String get zoneHintCold => 'بعيد. تحرّك حول المكان وانتظر نبضات أسرع.';
  @override
  String get signalStrength => 'قوة الإشارة';
  @override
  String get rawRssi => 'الخام';
  @override
  String get smoothedRssi => 'المنعّم';
  @override
  String get playSound => 'تشغيل صوت';
  @override
  String get playSoundHint => 'يرسل مستوى تنبيه إلى خدمة Alert على الجهاز';
  @override
  String get alertSent => 'تم إرسال أمر التنبيه';
  @override
  String get alertUnsupported => 'هذا الجهاز لا يوفّر خدمة تنبيه GATT';
  @override
  String get alertFailed => 'تعذر الوصول للجهاز — ربما لا يقبل الاتصال';
  @override
  String get markFound => 'تم العثور عليه';
  @override
  String get foundTitle => 'تم تحديد الهدف!';
  @override
  String foundBody(String name) => 'تم تسجيل $name كجهاز تم العثور عليه. أحسنت!';
  @override
  String get backToDevices => 'العودة للأجهزة';
  @override
  String get keepTracking => 'متابعة التتبع';
  @override
  String get geigerActive => 'نبضات القرب تعمل';
  @override
  String get geigerMuted => 'نبضات القرب صامتة';
  @override
  String get history => 'سجل الإشارة';
  @override
  String get liveFeed => 'بث مباشر';
  @override
  String get deviceDetails => 'تشخيص الإشارة';

  @override
  String get sweepAssistant => 'مسح ٣٦٠°';
  @override
  String get sweepTitle => 'محدد الاتجاه';
  @override
  String get sweepIntro =>
      'أمسك الهاتف أفقيًا ودُر ببطء دورة كاملة. يسجّل الرادار قوة الإشارة عند كل اتجاه.';
  @override
  String get sweepStart => 'بدء المسح';
  @override
  String get sweepProgress => 'تقدم المسح';
  @override
  String sweepDegreesLeft(int degrees) => 'باقٍ $degrees°';
  @override
  String get sweepComplete => 'اكتمل المسح';
  @override
  String get sweepPeakHeading => 'أقوى اتجاه';
  @override
  String get sweepConfidence => 'الثقة';
  @override
  String get sweepLock => 'تثبيت الاتجاه على الرادار';
  @override
  String get sweepAgain => 'إعادة المسح';
  @override
  String get sweepSimulated => 'الوضع التجريبي — دوران محاكى';
  @override
  String get sweepNoCompass => 'لا توجد بوصلة مغناطيسية — استخدام دوران محاكى.';
  @override
  String get compassUnavailable => 'البوصلة غير متوفرة';
  @override
  String get swipeHint => 'اسحب للأسفل للإغلاق';
  @override
  String get close => 'إغلاق';
  @override
  String get cancel => 'إلغاء';
  @override
  String get north => 'ش';
  @override
  String get south => 'ج';
  @override
  String get east => 'ق';
  @override
  String get west => 'غ';
  @override
  String headingDegrees(int degrees) => '$degrees°';

  @override
  String get settingsTitle => 'الإعدادات';
  @override
  String get sectionAppearance => 'المظهر';
  @override
  String get sectionSignal => 'معالجة الإشارة';
  @override
  String get sectionScanning => 'المسح';
  @override
  String get sectionAlerts => 'التنبيهات';
  @override
  String get sectionAbout => 'حول التطبيق';
  @override
  String get language => 'اللغة';
  @override
  String get languageArabic => 'العربية';
  @override
  String get languageEnglish => 'English';
  @override
  String get units => 'وحدات المسافة';
  @override
  String get unitsMetric => 'متر';
  @override
  String get unitsImperial => 'قدم';
  @override
  String get soundAlerts => 'نبضات صوتية';
  @override
  String get hapticAlerts => 'نبضات اهتزاز';
  @override
  String get mockData => 'بيانات بلوتوث وهمية';
  @override
  String get mockDataHint => 'توليد إشارات افتراضية — مثالية للمحاكيات';
  @override
  String get emaAlpha => 'تمهيد EMA';
  @override
  String get emaAlphaHint => 'أقل = أهدأ، أعلى = استجابة أسرع';
  @override
  String get pathLoss => 'معامل فقدان المسار (n)';
  @override
  String get pathLossHint => '2.0 فضاء حر · 2.5 داخل مبنى · 3.0+ عوائق';
  @override
  String get txPower => 'قوة الإرسال عند 1 م';
  @override
  String get txPowerHint => 'الإشارة المتوقعة على مسافة متر واحد';
  @override
  String get radarRange => 'مدى الرادار';
  @override
  String get radarRangeHint => 'الحلقة الخارجية لشاشة الرادار';
  @override
  String get calibrate => 'معايرة عند 1 متر';
  @override
  String get calibrateHint => 'قف على مسافة متر من الجهاز ثم اضغط لتعلم قوة إرساله.';
  @override
  String calibrated(String value) => 'تمت المعايرة — قوة الإرسال الآن $value dBm';
  @override
  String get calibrateFailed => 'لا يوجد جهاز مباشر للمعايرة';
  @override
  String get resetDefaults => 'استعادة الافتراضي';
  @override
  String get resetConfirmTitle => 'استعادة الإعدادات؟';
  @override
  String get resetConfirmBody => 'ستعود قوة الإرسال والمعامل والتمهيد وخيارات العرض لقيمها الأصلية.';
  @override
  String get reset => 'استعادة';
  @override
  String get aboutBody =>
      'رادار بلوتوث بتقنية Flutter يقدّر المسافة من قوة الإشارة عبر نموذج فقدان المسار، ثم ينعّم كل قراءة بمتوسط متحرك أسي.';
  @override
  String version(String version) => 'الإصدار $version';
  @override
  String get permissionsInfo => 'الأذونات';
  @override
  String get permissionListBody =>
      'BLUETOOTH_SCAN (neverForLocation) · BLUETOOTH_CONNECT · ACCESS_FINE_LOCATION (أندرويد 11 أو أقل)';
  @override
  String get disclaimer => 'المسافة المقدّرة من الإشارة تقريبية: الجدران والأجسام واتجاه الهوائي تغيّر القراءة.';
  @override
  String get settingsSaved => 'تم الحفظ';

  @override
  String get yes => 'نعم';
  @override
  String get no => 'لا';
  @override
  String get notAvailable => '—';
  @override
  String get signalLostTitle => 'فُقدت الإشارة';
  @override
  String get signalLostBody => 'توقف هذا الجهاز عن البث. اقترب أكثر أو أعد المسح.';
  @override
  String get scanAgain => 'إعادة المسح';
  @override
  String get pulseInterval => 'النبضة';
  @override
  String get alertService => 'خدمة التنبيه';
  @override
  String get advertisedTxPower => 'قوة الإرسال المعلنة';
  @override
  String get bearingLocked => 'تم تثبيت الاتجاه على الرادار';
  @override
  String get foundBadge => 'وُجد';

  @override
  String zoneLabel(ProximityZone zone) => zone.labelAr;
  @override
  String zoneRange(ProximityZone zone) => zone.rangeAr;
  @override
  String zoneHint(ProximityZone zone) => switch (zone) {
        ProximityZone.hot => zoneHintHot,
        ProximityZone.warm => zoneHintWarm,
        ProximityZone.moderate => zoneHintModerate,
        ProximityZone.cold => zoneHintCold,
      };
  @override
  String kindLabel(DeviceKind kind) => kind.labelAr;
  @override
  String get done => 'تم';
}

/// Localizations holder + delegate.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ?? const AppLocalizations(Locale('ar'));

  bool get isArabic => locale.languageCode == 'ar';

  Locale get textDirectionLocale => locale;

  AppStrings get strings => isArabic ? const AppStringsAr() : const AppStringsEn();

  String get languageCode => locale.languageCode;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ar' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  AppStrings get strings => AppLocalizations.of(this).strings;
}
