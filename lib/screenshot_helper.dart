// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 将 RepaintBoundary 包裹的聊天页截图为 PNG 并触发浏览器下载。
/// 像真机截图一样：包含状态栏 + 导航栏 + 消息 + 输入栏 + Home 指示条。
///
/// 文件名格式：`{标题}_{YYYYMMDD}_{HHMM}.png`（标题自动去除非法字符）。
Future<void> captureAndDownload(
  GlobalKey key, {
  String? title,
  double pixelRatio = 3.0,
}) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return;

  final now = DateTime.now();
  final stamp =
      '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
  final name = (title?.trim().isNotEmpty == true)
      ? _sanitize(title!.trim())
      : 'wechat_chat';
  final fileName = '${name}_$stamp.png';

  final pngBytes = byteData.buffer.asUint8List();
  final blob = html.Blob([pngBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 去除文件名中的非法 / 控制字符，并折叠空白，避免浏览器拒绝保存。
String _sanitize(String s) {
  const illegal = '<>:"/\\|?*';
  final buf = StringBuffer();
  for (final rune in s.runes) {
    if (rune == 32 || rune == 9 || rune == 10) {
      buf.write('_');
    } else if (rune >= 32 && !illegal.contains(String.fromCharCode(rune))) {
      buf.write(String.fromCharCode(rune));
    }
  }
  final out = buf.toString();
  return out.isEmpty ? 'wechat_chat' : out;
}
