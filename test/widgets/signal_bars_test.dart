import 'package:bluetooth_finder_radar/core/theme/radar_colors.dart';
import 'package:bluetooth_finder_radar/ui/widgets/common/signal_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(backgroundColor: RadarColors.background, body: Center(child: child)),
    );

void main() {
  group('SignalBars.barsForRssi', () {
    test('maps dBm to 0 … 4 bars', () {
      expect(SignalBars.barsForRssi(-40), 4);
      expect(SignalBars.barsForRssi(-55), 4);
      expect(SignalBars.barsForRssi(-60), 3);
      expect(SignalBars.barsForRssi(-70), 2);
      expect(SignalBars.barsForRssi(-80), 1);
      expect(SignalBars.barsForRssi(-95), 0);
    });
  });

  group('SignalBars widget', () {
    testWidgets('renders four bars and animates without throwing', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const SignalBars(rssi: -42)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byType(SignalBars), findsOneWidget);
    });

    testWidgets('respects the minimum bar count', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const SignalBars(rssi: -99, minBars: 1)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles a changing reading', (WidgetTester tester) async {
      await tester.pumpWidget(harness(const SignalBars(rssi: -80)));
      await tester.pumpWidget(harness(const SignalBars(rssi: -50)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });
  });
}
