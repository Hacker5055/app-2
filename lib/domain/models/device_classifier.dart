import 'device_kind.dart';

/// Name / advertisement based classification of nearby BLE devices.
///
/// Real-world advertisements are messy: many wearables only expose a model
/// string, trackers often advertise nothing at all. The classifier therefore
/// combines three independent hints, in order of confidence:
///
/// 1. Apple manufacturer data advertisement type
///    (`0x004C` company id + type byte) — lets us identify AirPods and
///    Find My / AirTag frames even when no local name is broadcast.
/// 2. The Immediate Alert GATT service (0x1802), which most finder tags expose.
/// 3. Keyword matching against the local name / advertised name.
class DeviceClassifier {
  const DeviceClassifier._();

  static const int appleCompanyId = 0x004C;
  static const int findMyType = 0x12;
  static const Set<int> airPodsTypes = <int>{0x07, 0x0E, 0x10, 0x19};

  static const String immediateAlertService = '1802';
  static const String immediateAlertServiceFull = '00001802-0000-1000-8000-00805f9b34fb';

  static const List<DeviceKind> _priority = <DeviceKind>[
    DeviceKind.earbuds,
    DeviceKind.tracker,
    DeviceKind.watch,
  ];

  static const Map<DeviceKind, List<String>> keywords = <DeviceKind, List<String>>{
    DeviceKind.earbuds: <String>[
      'airpods',
      'buds',
      'bud',
      'earbud',
      'earphone',
      'headphone',
      'headset',
      'beats',
      'jabra',
      'soundcore',
      'freebuds',
      'enco',
      'tws',
      'liberty',
      'airdots',
      'wf-',
      'wh-',
      'quietcomfort',
      'sennheiser',
      'momentum',
      'tozo',
      'haylou',
      'edifier',
      'speaker',
    ],
    DeviceKind.tracker: <String>[
      'airtag',
      'smarttag',
      'smart tag',
      'chipolo',
      'pebblebee',
      'findmy',
      'find my',
      'itag',
      'tile',
      'trackr',
      'tracker',
      'keyfinder',
      'key finder',
      'nut ',
      'nut-',
      'beacon',
      'tag',
      'lost item',
    ],
    DeviceKind.watch: <String>[
      'watch',
      'smartwatch',
      'gear',
      'wear',
      'band',
      'fitbit',
      'garmin',
      'amazfit',
      'versa',
      'huawei watch',
      'galaxy fit',
      'honor band',
      'mi band',
      'health',
    ],
  };

  /// Classifies a BLE advertisement.
  ///
  /// [manufacturerData] is the raw AD payload starting with the 16-bit company
  /// identifier (little endian), exactly as exposed by flutter_blue_plus.
  static DeviceKind classify({
    String? name,
    String? advertisedName,
    Iterable<String> serviceUuids = const <String>[],
    List<int> manufacturerData = const <int>[],
  }) {
    final String haystack = '${name ?? ''} ${advertisedName ?? ''}'.toLowerCase().trim();

    // 1. Apple continuity / Find My frames.
    final DeviceKind? appleKind = _classifyApple(manufacturerData);
    if (appleKind != null) return appleKind;

    // 2. Keyword matching — a real name always wins over generic UUID hints.
    for (final DeviceKind kind in _priority) {
      final List<String> rules = keywords[kind] ?? const <String>[];
      for (final String keyword in rules) {
        if (haystack.isNotEmpty && haystack.contains(keyword)) {
          return kind;
        }
      }
    }

    // 3. Generic finder-tag signature.
    if (serviceUuids.any((String uuid) {
      final String normalized = uuid.toLowerCase();
      return normalized == immediateAlertService || normalized.startsWith(immediateAlertServiceFull);
    })) {
      return DeviceKind.tracker;
    }

    return DeviceKind.unknown;
  }

  static DeviceKind? _classifyApple(List<int> manufacturerData) {
    if (manufacturerData.length < 3) return null;
    final int companyId = manufacturerData[0] | (manufacturerData[1] << 8);
    if (companyId != appleCompanyId) return null;
    final int type = manufacturerData[2];
    if (type == findMyType) return DeviceKind.tracker;
    if (airPodsTypes.contains(type)) return DeviceKind.earbuds;
    return null;
  }
}
