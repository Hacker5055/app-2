import '../../domain/models/ble_advertisement.dart';
import '../../domain/models/ble_status.dart';
import '../services/ble_scanner_service.dart';
import '../services/flutter_blue_scanner_service.dart';

/// Switches between the real radio and the mock generator.
///
/// Both scanners can be observed at all times; the controller filters by
/// `advertisement.isMock`. Only the active scanner is actually running, which
/// keeps the radio quiet while demo mode is on.
class BleRepository {
  BleRepository({
    required BleScannerService realScanner,
    required BleScannerService mockScanner,
  })  : _real = realScanner,
        _mock = mockScanner;

  final BleScannerService _real;
  final BleScannerService _mock;

  bool _mockActive = false;

  bool get isMockActive => _mockActive;

  BleScannerService get realScanner => _real;

  Stream<BleAdvertisement> get realAdvertisements => _real.advertisements;

  Stream<BleAdvertisement> get mockAdvertisements => _mock.advertisements;

  Stream<BleAdapterStatus> get realAdapterStatus => _real.adapterStatus;

  Stream<BleAdapterStatus> get mockAdapterStatus => _mock.adapterStatus;

  Stream<String> get realErrors => _real.errors;

  Stream<String> get mockErrors => _mock.errors;

  BleAdapterStatus get realAdapterState => _real.currentAdapterStatus;

  Future<void> activate({required bool useMock}) async {
    _mockActive = useMock;
    if (useMock) {
      await _real.stop();
      await _mock.start();
    } else {
      await _mock.stop();
      await _real.start();
    }
  }

  Future<void> stopAll() async {
    await _real.stop();
    await _mock.stop();
  }

  /// Shows Android's "enable Bluetooth" system dialog when possible.
  Future<bool> requestBluetoothEnable() async {
    if (_real is FlutterBlueScannerService) {
      return _real.requestTurnOn();
    }
    return false;
  }

  Future<void> dispose() async {
    await _real.dispose();
    await _mock.dispose();
  }
}
