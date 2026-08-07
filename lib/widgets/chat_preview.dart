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
  final bool showBatteryPercent; // iOS 16 风格：电量百分比显示在电池内

  const StatusBar({
    required this.time,
    this.batteryPercent = 100,
    this.charging = false,
    this.signalLevel = 4,
    this.showWifi = true,
    this.showBatteryPercent = true,
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
              _BatteryIcon(
                percent: batteryPercent,
                charging: charging,
                showPercent: showBatteryPercent,
              ),
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

/// WiFi（真机矢量图：以圆点为中心的三段同心弧，完整无裁切）
class _WifiIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/status_bar/wifi.svg',
      width: WeChatTheme.statusBarIconSize,
      height: WeChatTheme.statusBarIconSize * 18 / 18,
      colorFilter:
          ColorFilter.mode(WeChatTheme.statusBarIconColor, BlendMode.srcIn),
    );
  }
}

/// 电池（iOS 16 真机风格）：
/// - 显示百分比：电池整体填满（黑/绿/红），白色数字居中，无 % 符号（真机行为）
/// - 不显示百分比：仅描边外壳，内部按实际电量绘制填充条
/// - 充电时绿色填充 + 闪电；低电量（≤20%）红色填充
class _BatteryIcon extends StatelessWidget {
  final int percent;
  final bool charging;
  final bool showPercent;
  const _BatteryIcon({
    required this.percent,
    required this.charging,
    this.showPercent = true,
  });

  // 电池 SVG viewBox = 26 x 13，外壳与右侧小帽比例固定
  static const double _vbW = 26, _vbH = 13;
  static const double _innerPad = 0.8; // 使填充与描边外壳内边缘贴合

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0, 100);

    // —— 颜色逻辑（与真机 iOS 一致）——
    final Color fill;
    if (p <= 20) {
      fill = WeChatTheme.iosBatteryRed;
    } else if (charging) {
      fill = WeChatTheme.iosBatteryGreen;
    } else {
      fill = WeChatTheme.statusBarIconColor;
    }
    const textColor = Colors.white;

    // —— 尺寸：显示百分比时略宽，整体保持 2:1 比例 ——
    final double w = showPercent ? 25.5 : 25.0;
    final double h = w * _vbH / _vbW;
    final double sx = w / _vbW;
    if (showPercent) {
      // 电池主体内部区域（不含右侧小帽），数字与闪电严格数学居中于此
      final double bodyX = w * 0.8 / _vbW;
      final double bodyY = h * 0.8 / _vbH;
      final double bodyW = w * 21 / _vbW;
      final double bodyH = h * 11.4 / _vbH;
      final double numFont = bodyH * 0.82;

      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/icons/status_bar/battery_full.svg',
              width: w,
              height: h,
              colorFilter: ColorFilter.mode(fill, BlendMode.srcIn),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _BatteryLabelPainter(
                  percent: p,
                  charging: charging,
                  color: textColor,
                  fontSize: numFont,
                  bodyRect: Rect.fromLTWH(bodyX, bodyY, bodyW, bodyH),
                  fontFamily: WeChatTheme.fontFamily,
                  fontFallback: WeChatTheme.fontFallback,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 不显示百分比：描边外壳 + 内部填充条
    final double ix = (0.8 + _innerPad) * sx;
    final double iy = (0.8 + _innerPad) * (h / _vbH);
    final double iw = (21 - 2 * _innerPad) * sx;
    final double ih = (11.4 - 2 * _innerPad) * (h / _vbH);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/status_bar/battery_shell.svg',
            width: w,
            height: h,
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
                borderRadius: BorderRadius.circular(2 * sx),
              ),
            ),
          ),
          if (charging)
            SvgPicture.asset(
              'assets/icons/status_bar/battery_bolt.svg',
              width: h * 0.62 * 6.6 / 8.0,
              height: h * 0.62,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
        ],
      ),
    );
  }
}

/// 电池内文字 + 闪电：用 TextPainter 精确测量并按几何中心绘制，
/// 闪电用 Path 直接绘制，大小/位置均由几何算出——彻底去掉 FittedBox/Row 带来的目测偏差。
class _BatteryLabelPainter extends CustomPainter {
  final int percent;
  final bool charging;
  final Color color;
  final double fontSize;
  final Rect bodyRect;
  final String? fontFamily;
  final List<String>? fontFallback;
  const _BatteryLabelPainter({
    required this.percent,
    required this.charging,
    required this.color,
    required this.fontSize,
    required this.bodyRect,
    this.fontFamily,
    this.fontFallback,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = bodyRect.left + bodyRect.width / 2;
    final double cy = bodyRect.top + bodyRect.height / 2;

    final tp = TextPainter(
      text: TextSpan(
        text: '$percent',
        style: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1.0,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final double numW = tp.width;
    final double numH = tp.height;

    // 闪电：高度取数字约 72%，宽度按自然比例；位置与大小均由几何计算，无需目测微调
    final double boltH = fontSize * 0.72;
    final double boltW = boltH * 0.62;
    final double gap = boltW * 0.28;

    double numLeft;
    if (charging) {
      final double totalW = boltW + gap + numW;
      final double startX = cx - totalW / 2;
      _drawBolt(
          canvas, Rect.fromLTWH(startX, cy - boltH / 2, boltW, boltH), color);
      numLeft = startX + boltW + gap;
    } else {
      numLeft = cx - numW / 2;
    }

    // 数字竖直方向：以行盒几何中心对齐，并下移一个小的经验补偿使字形视觉居中
    final double numTop = cy - numH / 2 + fontSize * 0.05;
    tp.paint(canvas, Offset(numLeft, numTop));
  }

  void _drawBolt(Canvas canvas, Rect r, Color color) {
    final double w = r.width, h = r.height, l = r.left, t = r.top;
    final path = Path();
    path.moveTo(l + 0.55 * w, t + 0.00 * h);
    path.lineTo(l + 0.10 * w, t + 0.58 * h);
    path.lineTo(l + 0.42 * w, t + 0.58 * h);
    path.lineTo(l + 0.28 * w, t + 1.00 * h);
    path.lineTo(l + 0.90 * w, t + 0.38 * h);
    path.lineTo(l + 0.55 * w, t + 0.38 * h);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BatteryLabelPainter old) =>
      old.percent != percent ||
      old.charging != charging ||
      old.color != color ||
      old.fontSize != fontSize ||
      old.bodyRect != bodyRect;
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
            showBatteryPercent: widget.model.showBatteryPercent,
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
