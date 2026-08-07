import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'chat_models.dart';
import 'wechat_theme.dart';
import 'utils.dart';
import 'screenshot_helper.dart';
import 'widgets/chat_preview.dart';
import 'widgets/editor_panel.dart';

void main() => runApp(const MyApp());

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
      body: Row(
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
    );
  }
}
