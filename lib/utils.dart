// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 压缩配置常量
/// 尺寸按预览最大显示尺寸 ×2（视网膜）设定：图片消息显示上限 240px、
/// 头像 40px，源图更大只会白白增加 base64 体积与解码/绘制成本。
const int kMaxImageDimension = 480; // 图片消息最大边长（像素）
const int kMaxAvatarDimension = 128; // 头像最大边长（像素）
const double kJpegQuality = 0.8; // JPEG 压缩质量（0.0 ~ 1.0）

/// 通过文件选择器选取一张图片，压缩后返回 data URL（可直接用于 Image.memory）。
/// 仅 Web 端可用。
///
/// [isAvatar] 为 true 时使用 PNG 格式保留透明通道，并使用更小的尺寸限制。
Future<String?> pickImageAsDataUrl({bool isAvatar = false}) async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;

  final maxDim = isAvatar ? kMaxAvatarDimension : kMaxImageDimension;

  // 读取文件为 ArrayBuffer，创建 Object URL 加载到 ImageElement
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;

  final blob = html.Blob([reader.result as Object], file.type);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);

  final img = html.ImageElement();
  img.src = objectUrl;
  await img.onLoad.first;

  // 计算缩放后尺寸（保持宽高比）
  var w = img.naturalWidth;
  var h = img.naturalHeight;
  if (w <= 0 || h <= 0) {
    html.Url.revokeObjectUrl(objectUrl);
    // 回退：直接读取为 data URL（不压缩）
    return _fallbackDataUrl(file);
  }

  if (w > maxDim || h > maxDim) {
    if (w > h) {
      h = (h * maxDim / w).round();
      w = maxDim;
    } else {
      w = (w * maxDim / h).round();
      h = maxDim;
    }
  }

  // 绘制到 Canvas（缩放）
  final canvas = html.CanvasElement(width: w, height: h);
  canvas.context2D.drawImageScaled(img, 0, 0, w, h);

  // 头像保留 PNG 透明通道，图片消息用 JPEG 压缩
  final mimeType = isAvatar ? 'image/png' : 'image/jpeg';
  final quality = isAvatar ? null : kJpegQuality;
  final dataUrl = canvas.toDataUrl(mimeType, quality);

  html.Url.revokeObjectUrl(objectUrl);
  return dataUrl;
}

/// 回退方案：直接读取为 data URL（不压缩，仅在 Canvas 失败时使用）
Future<String?> _fallbackDataUrl(html.File file) async {
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
