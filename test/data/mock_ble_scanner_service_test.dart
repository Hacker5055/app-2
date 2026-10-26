import 'dart:async';

import 'package:bluetooth_finder_radar/data/services/ble_scanner_service.dart';
import 'package:bluetooth_finder_radar/data/services/mock_ble_scanner_service.dart';
import 'package:bluetooth_finder_radar/domain/models/ble_advertisement.dart';
import 'package:bluetooth_finder_radar/domain/models/ble_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockBleScannerService', () {
    late MockBleScannerService scanner;

    setUp(() {
      scanner = MockBleScannerService(tick: const Duration(milliseconds: 5));
    });

    tearDown(() async {
      await scanner.dispose();
    });

    test('is identifiable as the mock implementation', () {
      expect(scanner.isMock, isTrue);
      expect(scanner.name, 'mock');
      expect(scanner.currentAdapterStatus, BleAdapterStatus.poweredOn);
    });

    test('emits the scripted devices, tagged as mock data', () async {
      final Completer<List<BleAdvertisement>> completer = Completer<List<BleAdvertisement>>();
      final List<BleAdvertisement> captured = <BleAdvertisement>[];
      final StreamSubscription<BleAdvertisement> subscription =
          scanner.advertisements.listen((BleAdvertisement advertisement) {
        captured.add(advertisement);
        if (!completer.isCompleted && captured.length >= 24) {
          completer.complete(captured);
        }
      });

      await scanner.start();
      final List<BleAdvertisement> batch =
          await completer.future.timeout(const Duration(seconds: 5));
      await scanner.stop();
      await subscription.cancel();

      expect(batch, isNotEmpty);
      expect(batch.every((BleAdvertisement a) => a.isMock), isTrue);
      expect(batch.every((BleAdvertisement a) => a.id.startsWith('mock:')), isTrue);
      expect(batch.every((BleAdvertisement a) => a.name.isNotEmpty), isTrue);
      expect(
        batch.every((BleAdvertisement a) => a.rssi >= -100 && a.rssi <= -28),
        isTrue,
      );

      final Set<String> ids = batch.map((BleAdvertisement a) => a.id).toSet();
      expect(ids.length, greaterThanOrEqualTo(4));
      expect(ids, contains('mock:airpods-pro-2'));
    });

    test('announces poweredOn when scanning starts', () async {
      final Future<BleAdapterStatus> first = scanner.adapterStatus.first;
      await scanner.start();
      expect(await first.timeout(const Duration(seconds: 2)), BleAdapterStatus.poweredOn);
    });

    test('stops emitting after stop()', () async {
      await scanner.start();
      await scanner.advertisements.first.timeout(const Duration(seconds: 2));
      await scanner.stop();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      // No timer should be left running; dispose() must be safe to call twice.
      await scanner.dispose();
    });

    test('start() is safe to call repeatedly', () async {
      await scanner.start();
      await scanner.start();
      await scanner.advertisements.first.timeout(const Duration(seconds: 2));
    });
  });

  group('SimulatedDevice', () {
    test('is fully configured through named arguments', () {
      final SimulatedDevice device = SimulatedDevice(
        id: 'mock:test',
        name: 'Test',
        txPower: -59,
        distance: 2,
        connectable: false,
        hasAlertService: true,
        serviceUuids: <String>['180d'],
        visibility: 0.5,
        packetSkip: 1,
      );
      expect(device.id, 'mock:test');
      expect(device.hasAlertService, isTrue);
      expect(device.serviceUuids, <String>['180d']);
    });
  });
}
