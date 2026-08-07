import 'dart:math';
import 'package:flutter/material.dart';
import 'wechat_theme.dart';

/// 无头像成员随机分配一个头像底色（微信风格彩色方块）
Color randomAvatarColor() => WeChatTheme
    .avatarPalette[Random().nextInt(WeChatTheme.avatarPalette.length)];

/// 状态栏时钟，如 "9:41"（不补零，更接近真机）
String formatClock(DateTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

/// 大时间分割线文字，如 "上午 9:30" / "昨天 上午 9:30" / "3月2日 上午 9:30"
String formatDateDivider(DateTime t, {String? override}) {
  if (override != null && override.isNotEmpty) return override;
  final now = DateTime.now();
  final ampm = t.hour < 12 ? '上午' : '下午';
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final hm = '$h12:${t.minute.toString().padLeft(2, '0')}';
  if (t.year == now.year && t.month == now.month && t.day == now.day) {
    return '$ampm $hm';
  }
  if (t.year == now.year && t.month == now.month && t.day == now.day - 1) {
    return '昨天 $ampm $hm';
  }
  if (t.year == now.year) return '${t.month}月${t.day}日 $ampm $hm';
  return '${t.year}年${t.month}月${t.day}日 $ampm $hm';
}

/// 聊天成员（发送人 / 接收人）
class Member {
  String id;
  String name;
  String? avatarUrl; // data URL，为空则用首字 + 配色
  Color color; // 无头像时的底色
  bool isMe; // 是否为“我”（发送人）

  Member({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.color,
    this.isMe = false,
  });
}

/// 一条消息
/// type: text / image / system / divider
class ChatMessage {
  String id;
  String type;
  String? senderId; // text/image 时有效
  String content; // 文本 / 图片 data URL / 系统提示文字
  DateTime time;
  bool showDateDivider; // 在该消息前插入大时间分割线
  String? dateDividerText; // 分割线文字覆盖（为空则自动生成）

  ChatMessage({
    required this.id,
    this.type = 'text',
    this.senderId,
    this.content = '',
    required this.time,
    this.showDateDivider = false,
    this.dateDividerText,
  });
}

/// 整个聊天页的数据模型
class ChatModel {
  bool isGroup;
  String title;
  bool showMemberCount; // 群聊标题后是否显示 (N)
  List<Member> members;
  List<ChatMessage> messages;

  ChatModel({
    required this.isGroup,
    required this.title,
    this.showMemberCount = true,
    required this.members,
    required this.messages,
  });
}

/// 生成一个开箱即用的群聊示例
ChatModel sampleModel() {
  final zhang = Member(id: 'm1', name: '张三', color: WeChatTheme.avatarPalette[0]);
  final li = Member(id: 'm2', name: '李四', color: WeChatTheme.avatarPalette[1]);
  final wang = Member(id: 'm3', name: '王五', color: WeChatTheme.avatarPalette[2], isMe: true);
  final members = [zhang, li, wang];

  final now = DateTime.now();
  final t1 = now.subtract(const Duration(hours: 2, minutes: 10));
  final t2 = now.subtract(const Duration(hours: 2, minutes: 5));
  final t3 = now.subtract(const Duration(hours: 1, minutes: 40));
  final t4 = now.subtract(const Duration(minutes: 30));
  final t5 = now.subtract(const Duration(minutes: 28));

  final messages = [
    ChatMessage(id: 'msg0', type: 'divider', time: t1, showDateDivider: true, dateDividerText: '上午 9:30'),
    ChatMessage(id: 'msg1', type: 'text', senderId: 'm1', content: '在吗？周末一起去看前端展会吗', time: t1),
    ChatMessage(id: 'msg2', type: 'text', senderId: 'm2', content: '我也想去！听说这次有很多前端新技术分享', time: t2),
    ChatMessage(id: 'msg3', type: 'system', content: '李四 邀请 王五 加入了群聊', time: t2),
    ChatMessage(id: 'msg4', type: 'image', senderId: 'm2', content: '', time: t3),
    ChatMessage(id: 'msg5', type: 'text', senderId: 'm3', content: '好啊，那我们周六上午十点地铁口集合', time: t3),
    ChatMessage(id: 'msg6', type: 'text', senderId: 'm1', content: '收到～记得带上相机', time: t4),
    ChatMessage(id: 'msg7', type: 'text', senderId: 'm3', content: '没问题，到时候群里喊我', time: t5),
  ];

  return ChatModel(
    isGroup: true,
    title: '前端交流群',
    members: members,
    messages: messages,
  );
}

/// 单聊示例
ChatModel singleChatSample() {
  final me = Member(id: 'm1', name: '我', color: WeChatTheme.avatarPalette[3], isMe: true);
  final other = Member(id: 'm2', name: '林晓', color: WeChatTheme.avatarPalette[4]);
  final now = DateTime.now();
  final messages = [
    ChatMessage(id: 's0', type: 'divider', time: now.subtract(const Duration(hours: 1)), showDateDivider: true, dateDividerText: '上午 10:00'),
    ChatMessage(id: 's1', type: 'text', senderId: 'm2', content: '今晚有空一起吃饭吗？', time: now.subtract(const Duration(minutes: 50))),
    ChatMessage(id: 's2', type: 'text', senderId: 'm1', content: '可以啊，七点老地方？', time: now.subtract(const Duration(minutes: 48))),
    ChatMessage(id: 's3', type: 'text', senderId: 'm2', content: '好嘞，等你', time: now.subtract(const Duration(minutes: 10))),
  ];
  return ChatModel(
    isGroup: false,
    title: '林晓',
    showMemberCount: false,
    members: [me, other],
    messages: messages,
  );
}
