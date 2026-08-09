import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///  微信聊天详情页 —— 全局视觉规范（单一数据源 / Single Source of Truth）
/// ═══════════════════════════════════════════════════════════════════════════
///
/// 所有颜色、字号、间距、圆角、图标尺寸都集中在此文件。
/// 改一处即可全局生效，便于统一调参与像素级还原。
///
/// 【字号档位】（jadx + arsc 交叉验证：系统默认字体，全 Regular，无 bold）
///   - 17sp：主标题 / 正文 / 已发文字 / 输入框 / 发送按钮
///   - 15sp：iOS 状态栏时间（状态栏特有，略大）
///   - 14sp：副标题（群成员数）/ 时间分割线 / 系统提示
///   - 12sp：群昵称
///   - 18sp：头像首字母（非规范档位，属于占位绘制，单独列出）
class WeChatTheme {
  // ══════════════════ 一、画布尺寸（逻辑像素，截图按比例输出） ════════════════
  static const double chatWidth = 375.0;
  static const double chatHeight = 812.0; // iPhone X 全屏逻辑高，整体保持手机比例
  static const double statusBarHeight = 44.0;
  static const double appBarHeight = 44.0;
  static const double homeIndicatorHeight = 34.0;

  // ══════════════════ 二、颜色 ══════════════════
  // —— 背景 ——
  static const Color pageBg = Color(0xFFEDEDED); // 页面 / 状态栏背景
  static const Color appBarBg = Color(0xFFEDEDED); // 导航栏背景（与页面同色）
  static const Color toolbarBg = Color(0xFFF7F7F7); // 底部输入栏背景
  static const Color brandGreen = Color(0xFF07C160); // 微信绿 / 发送按钮
  static const Color inputBoxBg = Color(0xFFFFFFFF); // 输入文本框白底

  // —— 文字色 ——
  static const Color textPrimary = Color(0xE5000000); // 接收文字（近黑，FG_0）
  static const Color textSent = Color(0xE6000000); // 已方文字（近黑，i_）
  static const Color titleColor = Color(0xE6000000); // 主标题 bx
  static const Color subTitleColor = Color(0x8C000000); // 第二行成员数 jj
  static const Color nicknameColor = Color(0xFF8A8A8A); // 群昵称 Link_100（蓝紫）
  static const Color timeSmallColor = Color(0x8C000000); // 单条时间戳 FG_3
  static const Color timeDividerColor = Color(0x4D000000); // 大时间分割线 FG_2
  static const Color systemTextColor = Color(0x4D000000); // 系统提示文字 FG_2（默认色）
  static const Color systemHighlightColor = Color(0xFF67689A); // 系统提示高亮段拼接色
  static const Color navDividerColor = Color(0xFFE5E5E5); // 导航栏底部 hairline
  static const Color iconColor = Color(0xE6000000); // 图标近黑（通用默认）
  static const Color hintColor = Color(0x4D000000); // 输入框提示灰

  // —— 状态栏电池（iOS 真机色，与系统状态栏一致）——
  static const Color iosBatteryGreen = Color(0xFF34C759); // 充电 / 满电绿
  static const Color iosBatteryRed = Color(0xFFFF3B30); // 低电量红（≤20%）
  static const Color iosBatteryYellow = Color(0xFFFFCC00); // 低电量模式黄
  static const Color iosBatteryGray = Color(0xFFD0D3D7); // 电池灰色背景蒙版

  // —— 图标颜色（按区域拆分，便于单独改色）——
  static const Color statusBarIconColor = iconColor; // 状态栏图标
  static const Color appBarIconColor = iconColor; // 导航栏图标
  static const Color inputBarIconColor = iconColor; // 输入栏图标（语音/麦克风/表情/加号）
  static const Color avatarInitialColor = Color(0xFFFFFFFF); // 头像首字（白）
  static const Color placeholderTextColor = Color(0x99000000); // 缺图占位文字

  // —— 气泡 / 胶囊 / 占位 ——
  static const Color bubbleReceived = Color(0xFFFFFFFF); // 对方气泡白
  static const Color bubbleSent = Color(0xFF95EC69); // 自己气泡绿
  static const Color systemBubbleBg = Color(0x14000000); // 系统提示胶囊底
  static const Color placeholderBg = Color(0x12000000); // 缺图 / 缺表情占位底

  // —— 头像默认配色（微信风格彩色方块）——
  static const List<Color> avatarPalette = [
    Color(0xFF5B8DEF),
    Color(0xFFF0A020),
    Color(0xFF4CAF50),
    Color(0xFFE0607E),
    Color(0xFF9C6ADE),
    Color(0xFF3DB4C0),
    Color(0xFFFF8A65),
    Color(0xFF7E8AA2),
  ];

  // ══════════════════ 三、字体 ══════════════════
  /// 状态栏时间（MiSans-Semibold-time：数字 + 冒号 子集）
  static const String fontStatusTime = 'MiSans-Semibold-time';
  /// 时间分割线（MiSans-Normal-time：数字 + 冒号 + 上午/下午/凌晨/晚上/早上/昨天/中午/年月日 子集）
  static const String fontTimeDivider = 'MiSans-Normal-time';
  /// 标题（MiSans-Demibold：完整字体）
  static const String fontTitle = 'MiSans-Demibold';
  /// 消息正文与其余场景（MiSans-Regular：完整字体，全局默认兜底）
  static const String fontBody = 'MiSans-Regular';

  /// 全局默认字体 = 正文字体（无特殊声明处一律使用）
  static const String fontFamily = fontBody;
  static const List<String> fontFallback = [
    'PingFang SC',
    'Microsoft YaHei',
    'Roboto',
    'sans-serif'
  ];

  // ══════════════════ 四、文本样式（全部 Regular） ══════════════════
  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontWeight: FontWeight.w400,
  );

  /// 状态栏时间（iOS 状态栏特有，15sp / Medium）
  static final TextStyle statusBarTimeStyle = _base.copyWith(
      fontSize: 15, fontWeight: FontWeight.w500, color: iconColor,
      fontFamily: fontStatusTime);

  /// 主标题 bx，17sp / Medium
  static final TextStyle titleStyle =
      _base.copyWith(fontSize: 17, color: titleColor, fontFamily: fontTitle);

  /// 副标题（群成员数，第二行）jj，14sp / Medium
  static final TextStyle subtitleStyle = _base.copyWith(
      fontSize: 14, color: subTitleColor, fontFamily: fontTitle);

  /// 接收消息正文，17sp
  static final TextStyle bodyStyle = _base.copyWith(fontSize: 15, color: textPrimary);

  /// 已发送消息正文，17sp
  static final TextStyle sentBodyStyle = _base.copyWith(fontSize: 15, color: textSent);

  /// 群昵称 Link_100，12sp
  static final TextStyle nicknameStyle =
      _base.copyWith(fontSize: 12, color: nicknameColor);

  /// 大时间分割线文字 FG_2，10sp / Normal-time 子集
  static final TextStyle timeDividerStyle =
      _base.copyWith(fontSize: 12, color: timeDividerColor, fontFamily: fontTimeDivider);

  /// 系统提示文字 FG_2，14sp
  static final TextStyle systemStyle =
      _base.copyWith(fontSize: 14, color: systemTextColor);

  /// 输入框文字 i_，17sp
  static final TextStyle inputStyle = _base.copyWith(fontSize: 17, color: textSent);

  /// 输入框提示灰 FG_2，17sp
  static final TextStyle hintStyle = _base.copyWith(fontSize: 17, color: hintColor);

  /// 头像首字母（占位绘制），18sp，白色
  static final TextStyle avatarInitialStyle =
      _base.copyWith(fontSize: 18, color: avatarInitialColor);

  /// 发送按钮文字，17sp，白色
  static final TextStyle sendButtonStyle =
      _base.copyWith(fontSize: 17, color: Colors.white);

  /// 缺图 / 缺表情占位提示文字
  static final TextStyle placeholderStyle =
      _base.copyWith(fontSize: 14, color: placeholderTextColor);

  // ══════════════════ 五、聊天核心布局（统一约束源） ══════════════════
  static const double avatarSize = 40.0; // 头像尺寸
  static const double avatarGap = 8.0; // 头像与气泡之间的水平间距
  static const double messageGutter = 12.0; // 消息行左右外边距
  static const double bubbleRadius = 5.0; // 气泡圆角
  static const double avatarRadius = 4.0; // 头像圆角
  static const double inputMinHeight = 40.0; // 输入框最小高

  /// 统一的「消息内容锚定区」左边界：屏幕左缘 → 外边距 → 头像 → 间距
  static double get contentLeft =>
      messageGutter + avatarSize + avatarGap; // 60
  /// 统一的「消息内容锚定区」右边界：屏幕右缘 → 外边距 → 间距 → 头像
  static double get contentRight =>
      chatWidth - messageGutter - avatarGap - avatarSize; // 315
  /// 气泡（及所有消息内容）统一最大宽 = 锚定区宽度，收发两侧都锚定到同一区，
  /// 超长消息左右边缘天然对齐，互不越界。
  static double get bubbleMaxWidth => contentRight - contentLeft; // 255

  static const double imageMaxWidth = 180.0; // 图片消息最大宽（保持原比例）
  static const double imageMaxHeight = 240.0; // 图片消息最大高（保持原比例）
  static const double stickerSize = 120.0; // 表情消息固定正方形边长

  // ════════════════ 六、图标资源路径（集中管理） ════════════════
  /// 底部输入栏「语音」键（左侧圆圈声波）
  static const String voiceIconAsset = 'assets/icons/footer_voice_original.svg';
  /// 底部输入栏「麦克风」键（输入框右侧）
  static const String micIconAsset = 'assets/icons/input_mic_original.svg';
  /// 底部输入栏「表情」键
  static const String emojiIconAsset = 'assets/icons/footer_emoji_candidate.svg';
  /// 底部输入栏「加号」键
  static const String plusIconAsset = 'assets/icons/footer_plus.svg';

  // ════════════════ 七、组件级间距 / 尺寸（逐项可配） ════════════════
  // —— 状态栏 ——
  static const double statusBarPaddingH = 16.0; // 状态栏左右内边距
  static const double statusBarIconGap = 4.0; // 状态栏图标间隔
  static const double statusBarIconSize = 16.0; // 信号 / WiFi 图标尺寸
  static const double statusBarBatterySize = 20.0; // 电池图标尺寸

  // —— 导航栏 ——
  static const double appBarBackIconSize = 20.0; // 返回图标尺寸
  static const double appBarBackPaddingH = 6.0; // 返回按钮左右内边距
  static const double appBarMuteIconSize = 22.0; // 静音图标尺寸
  static const double appBarMoreIconSize = 24.0; // 更多图标尺寸
  static const double appBarRightGap = 4.0; // 右侧图标组右留白
  static const double appBarTitlePaddingH = 64.0; // 标题两侧避让（防与图标重叠）
  static const double navDividerWidth = 0.5; // 导航栏底部 hairline 线宽

  // —— 气泡 ——
  static const double bubblePaddingH = 12.0; // 气泡左右内边距
  static const double bubblePaddingV = 9.0; // 气泡上下内边距
  static const double bubbleTailWidth = 8.0; // 小三角宽
  static const double bubbleTailHeight = 14.0; // 小三角高
  static const double bubbleTailTop = 12.0; // 小三角距气泡顶
  static const double bubbleTailOffset = 6.0; // 小三角外伸距离

  // —— 消息行 ——
  static const double messageRowMarginV = 5.0; // 消息行上下外边距
  static const double nicknameBottomGap = 3.0; // 昵称与气泡间距
  static const double imagePlaceholderSize = 120.0; // 缺图占位方块边长

  // —— 系统提示胶囊 ——
  static const double systemMarginV = 8.0; // 系统提示上下外边距
  static const double systemMarginH = 24.0; // 系统提示左右外边距
  static const double systemPaddingH = 8.0; // 胶囊左右内边距
  static const double systemPaddingV = 4.0; // 胶囊上下内边距
  static const double systemRadius = 4.0; // 胶囊圆角

  // —— 大时间分割线 ——
  static const double timeDividerMarginV = 12.0; // 时间分割线上下外边距

  // —— 底部输入栏 ——
  static const double inputBarPaddingH = 8.0; // 输入栏左右内边距
  static const double inputBarPaddingV = 7.0; // 输入栏上下内边距
  static const double inputBarIconSize = 26.0; // 通用图标尺寸（备用）
  static const double inputBarVoiceIconSize = 32.0; // 左侧语音切换键（圆圈声波）
  static const double inputBarMicIconSize = 22.0; // 输入框右侧麦克风
  static const double inputBarEmojiIconSize = 30.0; // 表情键
  static const double inputBarPlusIconSize = 30.0; // 加号键
  static const double inputBarIconGap = 4.0; // 右侧图标之间的间隙
  static const double inputBoxRadius = 4.0; // 输入框圆角
  static const double inputBoxPaddingH = 8.0; // 输入框左右内边距
  static const double inputBoxPaddingV = 6.0; // 输入框上下内边距
  static const double sendBtnLeftGap = 4.0; // 发送按钮左间距
  static const double sendBtnRadius = 4.0; // 发送按钮圆角
  static const double sendBtnPaddingH = 14.0; // 发送按钮左右内边距
  static const double sendBtnPaddingV = 8.0; // 发送按钮上下内边距

  // —— Home 指示条 ——
  static const double homeIndicatorBarWidth = 134.0; // 黑条宽
  static const double homeIndicatorBarHeight = 5.0; // 黑条高
  static const double homeIndicatorBarRadius = 2.5; // 黑条圆角

  // ════════════════ 七、手机外壳（仅展示用，非截图内容，让预览更真实） ════════════════
  static const Color frameBg = Color(0xFF1C1C1E); // 外壳深色
  static const double frameOuterRadius = 46.0; // 外壳外圆角
  static const double frameInnerRadius = 36.0; // 屏幕圆角
  static const double framePadding = 10.0; // 外壳内边距（黑边）
  static const Color frameShadowColor = Color(0x40000000); // 外壳投影色
  static const double frameShadowBlur = 30.0; // 投影模糊
  static const double frameShadowSpread = 1.0; // 投影扩散
  static const double frameShadowY = 14.0; // 投影下移
  static const double notchTop = 9.0; // 刘海距顶
  static const double notchWidth = 118.0; // 刘海宽
  static const double notchHeight = 28.0; // 刘海高
  static const double notchRadius = 14.0; // 刘海圆角
}
