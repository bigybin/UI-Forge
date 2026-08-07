import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../chat_models.dart';
import '../wechat_theme.dart';

/// 隐藏滚动条：让聊天区滑动时不显示右侧进度条，更贴近真机观感
/// 同时保留鼠标 / 触摸 / 触控笔拖拽（否则只响应滚轮）
class NoScrollbarBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}

/// 微信风格 SVG 图标，自动按主题色统一着色
class WeChatIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color color;
  const WeChatIcon({
    required this.asset,
    this.size = WeChatTheme.inputBarIconSize,
    this.color = WeChatTheme.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// 手机外壳（仅展示用，不属于截图内容，让预览更真实美观）
class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WeChatTheme.frameBg,
        borderRadius: BorderRadius.circular(WeChatTheme.frameOuterRadius),
        boxShadow: [
          BoxShadow(
            color: WeChatTheme.frameShadowColor,
            blurRadius: WeChatTheme.frameShadowBlur,
            spreadRadius: WeChatTheme.frameShadowSpread,
            offset: Offset(0, WeChatTheme.frameShadowY),
          ),
        ],
      ),
      padding: EdgeInsets.all(WeChatTheme.framePadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WeChatTheme.frameInnerRadius),
        child: Stack(
          children: [
            child,
            Positioned(
              top: WeChatTheme.notchTop,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: WeChatTheme.notchWidth,
                  height: WeChatTheme.notchHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(WeChatTheme.notchRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ╔══════════════════════════════════════════════════════════╗
/// ║  聊天页完整预览：状态栏 + 导航栏 + 消息 + 输入栏 + Home  ║
/// ║  整体作为截图目标（外层包 RepaintBoundary）              ║
/// ╚══════════════════════════════════════════════════════════╝

/// 状态栏（仿 iOS 全面屏：时间 + 信号 / WiFi / 电池，全部使用真机矢量素材）
class StatusBar extends StatelessWidget {
  final String time;
  final int batteryPercent; // 0-100
  final bool charging;
  final int signalLevel; // 1-4 格
  final bool showWifi;

  const StatusBar({
    required this.time,
    this.batteryPercent = 100,
    this.charging = false,
    this.signalLevel = 4,
    this.showWifi = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WeChatTheme.statusBarHeight,
      color: WeChatTheme.pageBg,
      padding: EdgeInsets.symmetric(horizontal: WeChatTheme.statusBarPaddingH),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time, style: WeChatTheme.statusBarTimeStyle),
          Row(
            children: [
              _SignalIcon(level: signalLevel),
              SizedBox(width: WeChatTheme.statusBarIconGap),
              if (showWifi) ...[
                _WifiIcon(),
                SizedBox(width: WeChatTheme.statusBarIconGap),
              ],
              _BatteryIcon(percent: batteryPercent, charging: charging),
            ],
          ),
        ],
      ),
    );
  }
}

/// 蜂窝信号：按档位（1-4）切换真机矢量图
class _SignalIcon extends StatelessWidget {
  final int level;
  const _SignalIcon({required this.level});

  @override
  Widget build(BuildContext context) {
    final lvl = level.clamp(1, 4);
    return SvgPicture.asset(
      'assets/icons/status_bar/cellular_signal_$lvl.svg',
      width: WeChatTheme.statusBarIconSize,
      height: WeChatTheme.statusBarIconSize * 12 / 16,
      colorFilter:
          ColorFilter.mode(WeChatTheme.statusBarIconColor, BlendMode.srcIn),
    );
  }
}

/// WiFi（真机矢量图）
class _WifiIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/status_bar/wifi.svg',
      width: WeChatTheme.statusBarIconSize,
      height: WeChatTheme.statusBarIconSize * 14 / 18,
      colorFilter:
          ColorFilter.mode(WeChatTheme.statusBarIconColor, BlendMode.srcIn),
    );
  }
}

/// 电池：外壳用真机矢量图，电量填充按百分比由代码绘制
/// （低电量 ≤20% 变红、充电时变绿并显示闪电）
class _BatteryIcon extends StatelessWidget {
  final int percent;
  final bool charging;
  const _BatteryIcon({required this.percent, required this.charging});

  static const double _w = 25, _h = 12.5;
  static const double _sx = _w / 26, _sy = _h / 13;
  static const double _innerPad = 0.6;

  @override
  Widget build(BuildContext context) {
    final double ix = (0.8 + _innerPad) * _sx;
    final double iy = (0.8 + _innerPad) * _sy;
    final double iw = (21 - 2 * _innerPad) * _sx;
    final double ih = (11.4 - 2 * _innerPad) * _sy;
    final p = percent.clamp(0, 100);
    final Color fill = charging
        ? WeChatTheme.brandGreen
        : (p <= 20 ? const Color(0xFFF5343F) : WeChatTheme.statusBarIconColor);
    return SizedBox(
      width: _w,
      height: _h,
      child: Stack(
        children: [
          SvgPicture.asset(
            'assets/icons/status_bar/battery_shell.svg',
            width: _w,
            height: _h,
            colorFilter: ColorFilter.mode(
                WeChatTheme.statusBarIconColor, BlendMode.srcIn),
          ),
          Positioned(
            left: ix,
            top: iy,
            width: iw * p / 100,
            height: ih,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (charging)
            Center(
              child: SvgPicture.asset(
                'assets/icons/status_bar/battery_bolt.svg',
                width: _h * 0.62 * 24 / 13,
                height: _h * 0.62,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
        ],
      ),
    );
  }
}

/// 顶部导航栏：返回 / 标题(+群成员数) / 静音 / 更多
class ChatAppBar extends StatelessWidget {
  final String title;
  final bool isGroup;
  final int? memberCount;
  final bool showMemberCount;
  final VoidCallback? onBack;

  const ChatAppBar({
    required this.title,
    required this.isGroup,
    this.memberCount,
    this.showMemberCount = true,
    this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final display = (isGroup && showMemberCount && memberCount != null)
        ? '$title ($memberCount)'
        : title;
    return Container(
      height: WeChatTheme.appBarHeight,
      decoration: BoxDecoration(
        color: WeChatTheme.appBarBg,
        border: Border(
          bottom: BorderSide(
            color: WeChatTheme.navDividerColor,
            width: WeChatTheme.navDividerWidth,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  size: WeChatTheme.appBarBackIconSize, color: WeChatTheme.appBarIconColor),
              padding: EdgeInsets.only(
                  left: WeChatTheme.appBarBackPaddingH,
                  right: WeChatTheme.appBarBackPaddingH),
              onPressed: onBack ?? () {},
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none,
                      size: WeChatTheme.appBarMuteIconSize,
                      color: WeChatTheme.appBarIconColor),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz,
                      size: WeChatTheme.appBarMoreIconSize,
                      color: WeChatTheme.appBarIconColor),
                  onPressed: () {},
                ),
                SizedBox(width: WeChatTheme.appBarRightGap),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: WeChatTheme.appBarTitlePaddingH),
              child: Text(
                display,
                style: WeChatTheme.titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 头像（彩色底 + 首字，或上传图片）
class Avatar extends StatelessWidget {
  final Member member;
  final double size;
  const Avatar({required this.member, this.size = WeChatTheme.avatarSize, super.key});

  @override
  Widget build(BuildContext context) {
    final hasImg = member.avatarUrl != null && member.avatarUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasImg ? null : member.color,
        borderRadius: BorderRadius.circular(WeChatTheme.avatarRadius),
        image: hasImg
            ? DecorationImage(
                image: NetworkImage(member.avatarUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: hasImg
          ? null
          : Center(
              child: Text(
                member.name.isNotEmpty ? member.name[0] : '?',
                style: WeChatTheme.avatarInitialStyle,
              ),
            ),
    );
  }
}

/// 气泡小三角
class _TailPainter extends CustomPainter {
  final Color color;
  final bool isMe;
  _TailPainter(this.color, this.isMe);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path();
    if (isMe) {
      // 右侧气泡：三角向右（外侧）
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height / 2);
    } else {
      // 左侧气泡：三角向左（外侧）
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height / 2);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) =>
      old.color != color || old.isMe != isMe;
}

/// 气泡（接收 / 发送），带小三角
class WeChatBubble extends StatelessWidget {
  final bool isMe;
  final Widget child;
  final Color color;
  const WeChatBubble({
    required this.isMe,
    required this.child,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints:
              BoxConstraints(maxWidth: WeChatTheme.bubbleMaxWidth),
          padding: EdgeInsets.only(
            left: WeChatTheme.bubblePaddingH,
            right: WeChatTheme.bubblePaddingH,
            top: WeChatTheme.bubblePaddingV,
            bottom: WeChatTheme.bubblePaddingV,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(WeChatTheme.bubbleRadius),
          ),
          child: child,
        ),
        Positioned(
          top: WeChatTheme.bubbleTailTop,
          left: isMe ? null : -WeChatTheme.bubbleTailOffset,
          right: isMe ? -WeChatTheme.bubbleTailOffset : null,
          child: CustomPaint(
            size: Size(WeChatTheme.bubbleTailWidth, WeChatTheme.bubbleTailHeight),
            painter: _TailPainter(color, isMe),
          ),
        ),
      ],
    );
  }
}

/// 单条消息行（头像 + 昵称 + 气泡）
class MessageRow extends StatelessWidget {
  final ChatMessage msg;
  final Member? sender;
  final bool isGroup;
  final bool isMe;

  const MessageRow({
    required this.msg,
    required this.sender,
    required this.isGroup,
    required this.isMe,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Avatar(
        member: sender ??
            Member(id: '?', name: '?', color: Colors.grey));
    final Widget content;
    if (msg.type == 'image') {
      final img = msg.content.isNotEmpty
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: WeChatTheme.imageMaxWidth,
                maxHeight: WeChatTheme.imageMaxHeight,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(WeChatTheme.bubbleRadius),
                child: Image.network(
                  msg.content,
                  fit: BoxFit.contain,
                ),
              ),
            )
          : Container(
              width: WeChatTheme.imagePlaceholderSize,
              height: WeChatTheme.imagePlaceholderSize,
              color: WeChatTheme.placeholderBg,
              child: Center(
                  child: Text('（未设置图片）', style: WeChatTheme.placeholderStyle)),
            );
      // 图片消息：无气泡背景、无小三角，仅图片本身带与气泡一致的圆角，保持原图比例
      content = img;
    } else if (msg.type == 'sticker') {
      // 表情消息：固定正方形、不做圆角、支持 PNG 透明通道（无背景色）
      final s = WeChatTheme.stickerSize;
      content = msg.content.isNotEmpty
          ? Image.network(msg.content, width: s, height: s, fit: BoxFit.contain)
          : Container(
              width: s,
              height: s,
              color: WeChatTheme.placeholderBg,
              child: Center(
                  child: Text('（未设置表情）', style: WeChatTheme.placeholderStyle)),
            );
    } else {
      content = WeChatBubble(
        isMe: isMe,
        color: isMe ? WeChatTheme.bubbleSent : WeChatTheme.bubbleReceived,
        child: Text(
          msg.content,
          style: isMe ? WeChatTheme.sentBodyStyle : WeChatTheme.bodyStyle,
        ),
      );
    }

    final colChildren = <Widget>[
      if (isGroup && sender != null && !isMe)
        Padding(
          padding: EdgeInsets.only(bottom: WeChatTheme.nicknameBottomGap),
          child: Text(
            sender!.name,
            style: WeChatTheme.nicknameStyle,
            textAlign: TextAlign.left,
          ),
        ),
      content,
    ];

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: WeChatTheme.messageGutter,
          vertical: WeChatTheme.messageRowMarginV),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: EdgeInsets.only(right: WeChatTheme.avatarGap),
              child: avatar,
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: colChildren,
            ),
          ),
          if (isMe)
            Padding(
              padding: EdgeInsets.only(left: WeChatTheme.avatarGap),
              child: avatar,
            ),
        ],
      ),
    );
  }
}

/// 系统提示（浅灰胶囊）
class SystemMessage extends StatelessWidget {
  final String text;
  const SystemMessage({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
          vertical: WeChatTheme.systemMarginV,
          horizontal: WeChatTheme.systemMarginH),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: WeChatTheme.systemPaddingH,
              vertical: WeChatTheme.systemPaddingV),
          decoration: BoxDecoration(
            color: WeChatTheme.systemBubbleBg,
            borderRadius: BorderRadius.circular(WeChatTheme.systemRadius),
          ),
          child: Text(
            text,
            style: WeChatTheme.systemStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// 大时间分割线（居中灰字）
class TimeDivider extends StatelessWidget {
  final String text;
  const TimeDivider({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: WeChatTheme.timeDividerMarginV),
      child: Center(
        child: Text(text, style: WeChatTheme.timeDividerStyle),
      ),
    );
  }
}

/// 底部输入栏
class InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const InputBar({
    required this.controller,
    required this.onChanged,
    required this.onSend,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showSend = controller.text.trim().isNotEmpty;
    return Container(
      color: WeChatTheme.toolbarBg,
      padding: EdgeInsets.symmetric(
          horizontal: WeChatTheme.inputBarPaddingH,
          vertical: WeChatTheme.inputBarPaddingV),
      child: Row(
        children: [
          // 左侧：语音 / 键盘切换键（圆圈声波）
          IconButton(
            icon: WeChatIcon(
              asset: WeChatTheme.voiceIconAsset,
              size: WeChatTheme.inputBarVoiceIconSize,
              color: WeChatTheme.inputBarIconColor,
            ),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
          // 中间：输入框（麦克风置于输入框内部右侧）
          Expanded(
            child: Container(
              constraints:
                  BoxConstraints(minHeight: WeChatTheme.inputMinHeight),
              decoration: BoxDecoration(
                color: WeChatTheme.inputBoxBg,
                borderRadius: BorderRadius.circular(WeChatTheme.inputBoxRadius),
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: WeChatTheme.inputBoxPaddingH,
                  vertical: WeChatTheme.inputBoxPaddingV),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: null,
                style: WeChatTheme.inputStyle,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: WeChatIcon(
                    asset: WeChatTheme.micIconAsset,
                    size: WeChatTheme.inputBarMicIconSize,
                    color: WeChatTheme.inputBarIconColor,
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
            ),
          ),
          SizedBox(width: WeChatTheme.inputBarIconGap),
          IconButton(
            icon: WeChatIcon(
              asset: WeChatTheme.emojiIconAsset,
              size: WeChatTheme.inputBarEmojiIconSize,
              color: WeChatTheme.inputBarIconColor,
            ),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
          SizedBox(width: WeChatTheme.inputBarIconGap),
          IconButton(
            icon: WeChatIcon(
              asset: WeChatTheme.plusIconAsset,
              size: WeChatTheme.inputBarPlusIconSize,
              color: WeChatTheme.inputBarIconColor,
            ),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
          // 输入文字后出现的绿色发送按钮
          if (showSend)
            Padding(
              padding: EdgeInsets.only(left: WeChatTheme.sendBtnLeftGap),
              child: ElevatedButton(
                onPressed: onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WeChatTheme.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(WeChatTheme.sendBtnRadius)),
                  padding: EdgeInsets.symmetric(
                      horizontal: WeChatTheme.sendBtnPaddingH,
                      vertical: WeChatTheme.sendBtnPaddingV),
                ),
                child: Text('发送', style: WeChatTheme.sendButtonStyle),
              ),
            ),
        ],
      ),
    );
  }
}

/// Home 指示条（截图底部黑条）
class HomeIndicator extends StatelessWidget {
  const HomeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WeChatTheme.homeIndicatorHeight,
      color: WeChatTheme.toolbarBg,
      child: Center(
        child: Container(
          width: WeChatTheme.homeIndicatorBarWidth,
          height: WeChatTheme.homeIndicatorBarHeight,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius:
                BorderRadius.circular(WeChatTheme.homeIndicatorBarRadius),
          ),
        ),
      ),
    );
  }
}

/// 聊天页完整预览（截图目标内容）
///
/// 关键点：整体固定为手机比例（chatWidth × chatHeight），不会随消息变长；
/// 只有「消息区」用 Expanded + 内部 SingleChildScrollView 滚动，和微信一致。
/// 新增消息时自动滚到底部（微信行为）。截图只截当前视口，就像真机截图。
class ChatPreview extends StatefulWidget {
  final ChatModel model;
  final TextEditingController inputController;
  final ValueChanged<String> onInputChanged;
  final VoidCallback onSend;
  final VoidCallback onBack;

  const ChatPreview({
    required this.model,
    required this.inputController,
    required this.onInputChanged,
    required this.onSend,
    required this.onBack,
    super.key,
  });

  @override
  State<ChatPreview> createState() => _ChatPreviewState();
}

class _ChatPreviewState extends State<ChatPreview> {
  final ScrollController _scroll = ScrollController();
  int _prevLen = 0;

  @override
  void initState() {
    super.initState();
    _prevLen = widget.model.messages.length;
    // 首帧后滚到底
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(false));
  }

  @override
  void didUpdateWidget(covariant ChatPreview old) {
    super.didUpdateWidget(old);
    final len = widget.model.messages.length;
    if (len != _prevLen) {
      _prevLen = len;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom(true));
    }
  }

  void _scrollToBottom(bool animate) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position.maxScrollExtent;
    if (animate) {
      _scroll.animateTo(pos,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(pos);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final msg in widget.model.messages) {
      if (msg.type == 'divider') {
        children.add(TimeDivider(
            text: msg.dateDividerText ?? formatDateDivider(msg.time)));
        continue;
      }
      if (msg.showDateDivider) {
        children.add(TimeDivider(
            text: msg.dateDividerText ?? formatDateDivider(msg.time)));
      }
      if (msg.type == 'system') {
        children.add(SystemMessage(text: msg.content));
        continue;
      }
      final sender =
          widget.model.members.where((m) => m.id == msg.senderId).firstOrNull;
      final isMe = sender?.isMe ?? false;
      children.add(MessageRow(
        msg: msg,
        sender: sender,
        isGroup: widget.model.isGroup,
        isMe: isMe,
      ));
    }

    return Container(
      width: WeChatTheme.chatWidth,
      height: WeChatTheme.chatHeight,
      color: WeChatTheme.pageBg,
      child: Column(
        children: [
          StatusBar(
            time: (widget.model.statusBarTime?.isNotEmpty == true)
                ? widget.model.statusBarTime!
                : formatClock(DateTime.now()),
            batteryPercent: widget.model.batteryPercent,
            charging: widget.model.isCharging,
            signalLevel: widget.model.signalLevel,
            showWifi: widget.model.showWifi,
          ),
          ChatAppBar(
            title: widget.model.title,
            isGroup: widget.model.isGroup,
            memberCount: widget.model.members.length,
            showMemberCount: widget.model.showMemberCount,
            onBack: widget.onBack,
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: NoScrollbarBehavior(),
              child: SingleChildScrollView(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ),
          InputBar(
            controller: widget.inputController,
            onChanged: widget.onInputChanged,
            onSend: widget.onSend,
          ),
          const HomeIndicator(),
        ],
      ),
    );
  }
}
