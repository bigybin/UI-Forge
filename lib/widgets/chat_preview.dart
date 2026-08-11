import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../chat_models.dart';
import '../wechat_theme.dart';
import '../image_cache.dart';

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

/// 蜂窝信号：按档位（1-4）切换真机矢量图，并在左上角叠加 5G 角标
class _SignalIcon extends StatelessWidget {
  final int level;
  const _SignalIcon({required this.level});

  @override
  Widget build(BuildContext context) {
    final lvl = level.clamp(1, 4);
    const w = WeChatTheme.statusBarIconSize;
    const h = WeChatTheme.statusBarIconSize * 12 / 16;
    const color = WeChatTheme.statusBarIconColor;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(
            'assets/icons/status_bar/cellular_signal_$lvl.svg',
            width: w,
            height: h,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          // 左上角 5G 角标
          Positioned(
            left: -1.5,
            top: -1.5,
            child: SvgPicture.asset(
              'assets/icons/status_bar/5g_badge.svg',
              width: w * 0.50,
              height: w * 0.50 * 434 / 776,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ],
      ),
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
/// - 显示百分比：灰色背景蒙版 + 按电量叠加进度蒙版（黑/绿/红），白色数字居中，无 % 符号
/// - 不显示百分比：灰色外壳 + 内部进度填充条
/// - 充电时进度蒙版为绿色 + 电池右侧闪电；低电量（≤20%）红色
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

    // —— 进度蒙版颜色逻辑（与真机 iOS 一致）——
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

    // —— 主体区域（不含右侧小帽），数值与进度条据此居中对齐 ——
    final double bodyX = w * 0.8 / _vbW;
    final double bodyY = h * 0.8 / _vbH;
    final double bodyW = w * 21 / _vbW;
    final double bodyH = h * 11.4 / _vbH;

    // —— 进度蒙版区域：无百分比时向内缩进，贴合描边外壳内边缘 ——
    final double fillX = showPercent ? bodyX : bodyX + _innerPad * sx;
    final double fillY = showPercent ? bodyY : bodyY + _innerPad * sx;
    final double fillW =
        showPercent ? bodyW : bodyW - 2 * _innerPad * sx;
    final double fillH =
        showPercent ? bodyH : bodyH - 2 * _innerPad * sx;
    final double fillRadius = showPercent ? 2.5 * sx : 2 * sx;

    // —— 主体部分：灰色背景 + 进度蒙版（两分支共用）——
    final body = SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 灰色背景蒙版（描边外壳，无百分比时使用）
          if (!showPercent)
            SvgPicture.asset(
              'assets/icons/status_bar/battery_shell.svg',
              width: w,
              height: h,
              colorFilter: ColorFilter.mode(
                  WeChatTheme.iosBatteryGray, BlendMode.srcIn),
            )
          else
            SvgPicture.asset(
              'assets/icons/status_bar/battery_full.svg',
              width: w,
              height: h,
              colorFilter: ColorFilter.mode(
                  WeChatTheme.iosBatteryGray, BlendMode.srcIn),
            ),
          // 进度蒙版：按电量比例叠加，充电绿 / 低电红 / 普通黑
          Positioned(
            left: fillX,
            top: fillY,
            width: fillW * p / 100,
            height: fillH,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(fillRadius),
              ),
            ),
          ),
          // 白色电量数字（居中于主体），仅显示百分比时
          if (showPercent)
            Positioned.fill(
              child: CustomPaint(
                painter: _BatteryLabelPainter(
                  percent: p,
                  color: textColor,
                  fontSize: bodyH * 0.82,
                  bodyRect: Rect.fromLTWH(bodyX, bodyY, bodyW, bodyH),
                  fontFamily: WeChatTheme.fontFamily,
                  fontFallback: WeChatTheme.fontFallback,
                ),
              ),
            ),
        ],
      ),
    );

    // —— 充电闪电：位于电池右侧（外部），黑色且较大 ——
    final bolt = SvgPicture.asset(
      'assets/icons/status_bar/battery_bolt.svg',
      colorFilter: ColorFilter.mode(
          WeChatTheme.statusBarIconColor, BlendMode.srcIn),
    );

    final boltHeight = h * 0.8;
    final boltWidth = boltHeight * 512 / 853.333; // 快充字形宽高比（第一版基准备后微调）

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        if (charging) ...[
          SizedBox(width: 2.0),
          SizedBox(width: boltWidth, height: boltHeight, child: bolt),
        ],
      ],
    );
  }
}

/// 电池内白色电量数字：用 TextPainter 精确测量并按主体几何中心绘制，
/// 无闪电（闪电已外移到电池右侧），彻底避免数字偏移导致的「不居中」。
class _BatteryLabelPainter extends CustomPainter {
  final int percent;
  final Color color;
  final double fontSize;
  final Rect bodyRect;
  final String? fontFamily;
  final List<String>? fontFallback;
  const _BatteryLabelPainter({
    required this.percent,
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

    // 水平居中于主体；垂直方向按字形视觉中心对齐（数字属 cap-height 字形，
    // 视觉主体在行盒中心之上，故以 baseline - capHeight/2 计算，避免偏上）
    final double numLeft = cx - numW / 2;
    final double numTop =
        cy - (tp.computeLineMetrics().first.baseline - fontSize * 0.72 / 2);
    tp.paint(canvas, Offset(numLeft, numTop));
  }

  @override
  bool shouldRepaint(covariant _BatteryLabelPainter old) =>
      old.percent != percent ||
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
    final url = member.avatarUrl;
    final hasImg = url != null && url.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasImg ? null : member.color,
        borderRadius: BorderRadius.circular(WeChatTheme.avatarRadius),
        image: hasImg
            ? DecorationImage(
                // 按显示尺寸解码（2x 防锯齿），避免 256px 原图全尺寸占用内存
                image: ResizeImage(
                  CachedDataUrlImageProvider(url),
                  width: (size * 2).round(),
                ),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('Avatar: failed to load image: $exception');
                },
              )
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
                child: CachedMemoryImage(
                  dataUrl: msg.content,
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
          ? CachedMemoryImage(
              dataUrl: msg.content,
              width: s,
              height: s,
              fit: BoxFit.contain,
              cacheWidth: (s * 2).round(),
            )
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

/// 系统提示：无背景，多片段双色拼接成一行（默认色 + 高亮色）
class SystemMessage extends StatelessWidget {
  final List<SystemSegment> segments;
  const SystemMessage({required this.segments, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
          vertical: WeChatTheme.systemMarginV,
          horizontal: WeChatTheme.systemMarginH),
      child: Center(
        child: Text.rich(
          TextSpan(
            style: WeChatTheme.systemStyle,
            children: [
              for (final seg in segments)
                TextSpan(
                  text: seg.text,
                  style: seg.highlight
                      ? const TextStyle(color: WeChatTheme.systemHighlightColor)
                      : null,
                ),
            ],
          ),
          textAlign: TextAlign.center,
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
          Container(width: 8,),
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
        children.add(RepaintBoundary(
            child: TimeDivider(
                text: msg.dateDividerText ?? formatDateDivider(msg.time))));
        continue;
      }
      if (msg.showDateDivider) {
        children.add(RepaintBoundary(
            child: TimeDivider(
                text: msg.dateDividerText ?? formatDateDivider(msg.time))));
      }
      if (msg.type == 'system') {
        final segs = msg.segments.isNotEmpty
            ? msg.segments
            : [SystemSegment(id: msg.id, text: msg.content)];
        children.add(RepaintBoundary(child: SystemMessage(segments: segs)));
        continue;
      }
      final sender =
          widget.model.members.where((m) => m.id == msg.senderId).firstOrNull;
      final isMe = sender?.isMe ?? false;
      // 每条消息独立 RepaintBoundary：滚动时各行作为已栅格化图层平移，
      // 只有真正变化/新滚入视口的行才重绘，避免整机每帧全量重绘造成卡顿。
      children.add(RepaintBoundary(
        child: MessageRow(
          msg: msg,
          sender: sender,
          isGroup: widget.model.isGroup,
          isMe: isMe,
        ),
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
