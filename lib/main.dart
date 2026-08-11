import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:web/web.dart' as web;
import 'chat_models.dart';
import 'wechat_theme.dart';
import 'utils.dart';
import 'screenshot_helper.dart';
import 'widgets/chat_preview.dart';
import 'widgets/editor_panel.dart';

void main() {
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => _hideAppLoader());
}

/// Flutter 首帧渲染完成后，淡出并移除 index.html 中的加载动画
void _hideAppLoader() {
  final loader = web.document.getElementById('app-loader');
  if (loader == null) return;
  loader.className = 'fade-out';
  Future<void>.delayed(const Duration(milliseconds: 300), () => loader.remove());
}

/// 允许鼠标 / 触摸 / 触控笔拖拽滚动，模拟原版可直接拖动滑动的手感
class MyScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '微信聊天详情页 · 复刻 & 截图',
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyScrollBehavior(),
      theme: ThemeData(
        fontFamily: WeChatTheme.fontFamily,
        scaffoldBackgroundColor: const Color(0xFFE0E0E0),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ChatModel model;
  late TextEditingController inputController;
  final GlobalKey previewKey = GlobalKey();

  /// 版本号通知器：EditorPanel 数据变化时递增，触发 ChatPreview 重建。
  /// 使用 ValueNotifier 而非直接 setState，避免左侧输入时重建整个左侧面板。
  final ValueNotifier<int> _versionNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    model = sampleModel();
    inputController = TextEditingController();
  }

  @override
  void dispose() {
    inputController.dispose();
    _versionNotifier.dispose();
    super.dispose();
  }

  /// 输入框内容变化 — 不再触发全树重建，TextField 自身管理输入状态。
  /// 右侧预览区只在实际数据变化时通过 _versionNotifier 重建。
  void _onInputChanged(String v) {}

  void _onSend() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    final me = model.members.firstWhere((m) => m.isMe,
        orElse: () => model.members.first);
    model.messages.add(ChatMessage(
      id: shortId(),
      type: 'text',
      senderId: me.id,
      content: text,
      time: DateTime.now(),
    ));
    inputController.clear();
    _versionNotifier.value++;
  }

  Future<void> _download() async {
    await captureAndDownload(previewKey, title: model.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('微信聊天详情页 · 复刻 & 截图'),
        backgroundColor: WeChatTheme.toolbarBg,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 420,
            child: EditorPanel(
              model: model,
              onChanged: () => _versionNotifier.value++,
              onDownload: _download,
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFE0E0E0),
              child: ScrollConfiguration(
                behavior: NoScrollbarBehavior(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _versionNotifier,
                      builder: (context, version, child) => PhoneFrame(
                        child: RepaintBoundary(
                          key: previewKey,
                          child: ChatPreview(
                            model: model,
                            inputController: inputController,
                            onInputChanged: _onInputChanged,
                            onSend: _onSend,
                            onBack: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
