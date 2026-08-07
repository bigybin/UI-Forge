import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/chat_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('battery zoom 82 charging', (tester) async {
    await tester.binding.setSurfaceSize(const Size(2400, 200));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          body: Center(
            child: Transform.scale(
              scale: 5.0,
              child: const StatusBar(
                time: '9:41',
                batteryPercent: 82,
                charging: true,
                signalLevel: 4,
                showWifi: false,
                showBatteryPercent: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('battery_zoom.png'),
    );
  });
}
