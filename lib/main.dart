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

  @override
  void initState() {
    super.initState();
    model = sampleModel();
    inputController = TextEditingController();
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  void _onInputChanged(String v) => setState(() {});

  void _onSend() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    final me = model.members.firstWhere((m) => m.isMe,
        orElse: () => model.members.first);
    setState(() {
      model.messages.add(ChatMessage(
        id: shortId(),
        type: 'text',
        senderId: me.id,
        content: text,
        time: DateTime.now(),
      ));
      inputController.clear();
    });
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
      body: Column(
        children: [
          // 网页顶部系统设置区域：电池电量、系统时间，修改后实时显示
          _SystemSettingsBar(
            model: model,
            onChanged: () => setState(() {}),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 420,
                  child: EditorPanel(
                    model: model,
                    onChanged: () => setState(() {}),
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
                          child: PhoneFrame(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 网页顶部系统设置区域
/// - 电池电量滑块 + 充电开关
/// - 系统时间输入 + "当前"按钮
/// 所有改动都会通过 [onChanged] 触发预览重建，实时生效
class _SystemSettingsBar extends StatefulWidget {
  final ChatModel model;
  final VoidCallback onChanged;

  const _SystemSettingsBar({
    required this.model,
    required this.onChanged,
  });

  @override
  State<_SystemSettingsBar> createState() => _SystemSettingsBarState();
}

class _SystemSettingsBarState extends State<_SystemSettingsBar> {
  late final TextEditingController _timeCtrl;
  late final FocusNode _timeFocus;

  @override
  void initState() {
    super.initState();
    _timeCtrl = TextEditingController(text: widget.model.statusBarTime ?? '');
    _timeFocus = FocusNode();
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _timeFocus.dispose();
    super.dispose();
  }

  /// 将时间输入框同步为当前模型值（仅在未聚焦时改写，避免打断用户输入）
  void _syncTime() {
    final target = widget.model.statusBarTime ?? '';
    if (!_timeFocus.hasFocus && _timeCtrl.text != target) {
      _timeCtrl.text = target;
    }
  }

  void _setCurrentTime() {
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    widget.model.statusBarTime = '$h:$m';
    _timeCtrl.text = widget.model.statusBarTime!;
    widget.onChanged();
  }

  static TextStyle get _labelStyle => const TextStyle(
        fontSize: 13,
        color: Colors.black54,
      );

  static TextStyle get _valueStyle => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );

  @override
  Widget build(BuildContext context) {
    _syncTime();
    final model = widget.model;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 标题
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Text('系统设置', style: _valueStyle),
            ],
          ),

          // 电池电量
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('电池电量', style: _labelStyle),
              const SizedBox(width: 8),
                SizedBox(
                width: 140,
                child: Slider(
                  value: model.batteryPercent.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: WeChatTheme.brandGreen,
                  label: '${model.batteryPercent}%',
                  onChanged: (v) {
                    model.batteryPercent = v.round();
                    widget.onChanged();
                  },
                ),
              ),
              SizedBox(
                width: 36,
                child: Text('${model.batteryPercent}%', style: _valueStyle),
              ),
            ],
          ),

          // 充电开关
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('充电中', style: _labelStyle),
              Switch(
                value: model.isCharging,
                activeThumbColor: WeChatTheme.brandGreen,
                onChanged: (v) {
                  model.isCharging = v;
                  widget.onChanged();
                },
              ),
            ],
          ),

          // 系统时间
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('系统时间', style: _labelStyle),
              const SizedBox(width: 8),
              SizedBox(
                width: 82,
                height: 36,
                child: TextField(
                  controller: _timeCtrl,
                  focusNode: _timeFocus,
                  textAlign: TextAlign.center,
                  style: _valueStyle,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                    hintText: '9:41',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    model.statusBarTime = v.isEmpty ? null : v;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _setCurrentTime,
                icon: const Icon(Icons.access_time, size: 16),
                label: const Text('当前', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
