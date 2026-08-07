// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 通过文件选择器选取一张图片，返回 data URL（可直接用于 Image.network）。
/// 仅 Web 端可用。
Future<String?> pickImageAsDataUrl() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;
  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;
  final result = reader.result;
  if (result is String) return result;
  return null;
}

/// 生成短随机 id
String shortId() {
  return DateTime.now().microsecondsSinceEpoch.toRadixString(16) +
      DateTime.now().millisecond.toRadixString(16);
}
