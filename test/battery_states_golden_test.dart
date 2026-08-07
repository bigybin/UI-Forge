import 'package:flutter/material.dart';
import 'package:flutter_project/widgets/chat_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('battery states', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 260));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _scaledStatusBar(charging: false, percent: 82, label: '82% 正常'),
                _scaledStatusBar(charging: true, percent: 82, label: '82% 充电'),
                _scaledStatusBar(charging: true, percent: 100, label: '100% 充电'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('battery_states.png'),
    );
  });
}

Widget _scaledStatusBar({
  required bool charging,
  required int percent,
  required String label,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 10),
      Transform.scale(
        scale: 2.0,
        child: StatusBar(
          time: '9:41',
          batteryPercent: percent,
          charging: charging,
          signalLevel: 4,
          showWifi: true,
          showBatteryPercent: true,
        ),
      ),
    ],
  );
}
