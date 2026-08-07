import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/widgets/chat_preview.dart';

void main() {
  testWidgets('status bar full golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
          key: const ValueKey('root'),
          width: 375,
          height: 812,
          color: const Color(0xFFEDEDED),
          child: const Column(
            children: [
              StatusBar(
                time: '9:41',
                batteryPercent: 82,
                charging: false,
                signalLevel: 4,
                showWifi: true,
                showBatteryPercent: true,
              ),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('root')),
      matchesGoldenFile('status_bar_full.png'),
    );
  });
}
