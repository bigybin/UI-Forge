import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wifi icon check', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 360));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
          color: const Color(0xFFEDEDED),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WiFi 大图（检查是否完整）',
                    style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                // 放大渲染，确认无裁切
                SvgPicture.asset(
                  'assets/icons/status_bar/wifi.svg',
                  width: 96,
                  height: 96 * 13 / 18,
                  colorFilter:
                      const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                const SizedBox(height: 24),
                const Text('状态栏内效果（信号+WiFi+电池）',
                    style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  color: const Color(0xFFEDEDED),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/status_bar/cellular_signal_4.svg',
                        width: 18,
                        height: 13.5,
                        colorFilter: const ColorFilter.mode(
                            Colors.black, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 6),
                      SvgPicture.asset(
                        'assets/icons/status_bar/wifi.svg',
                        width: 18,
                        height: 18 * 13 / 18,
                        colorFilter: const ColorFilter.mode(
                            Colors.black, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 6),
                      SvgPicture.asset(
                        'assets/icons/status_bar/battery_full.svg',
                        width: 26,
                        height: 13,
                        colorFilter: const ColorFilter.mode(
                            Colors.black, BlendMode.srcIn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('wifi_check.png'),
    );
  });
}
