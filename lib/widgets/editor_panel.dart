import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chat_models.dart';
import '../wechat_theme.dart';
import '../utils.dart';
import '../image_cache.dart';
import '../widgets/chat_preview.dart';

/// 左侧编辑器面板：自定义聊天内容，并触发截图下载
class EditorPanel extends StatefulWidget {
  final ChatModel model;
  final VoidCallback onChanged; // 触发父级重建（实时预览）
  final VoidCallback onDownload; // 下载截图

  const EditorPanel({
    required this.model,
    required this.onChanged,
    required this.onDownload,
    super.key,
  });

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  // 文本控制器缓存（避免每次 rebuild 丢光标）
  final Map<String, TextEditingController> _tc = {};

  TextEditingController _ctrl(String key, String initial) {
    return _tc.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  @override
  void dispose() {
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 数据变更：本地重建左侧面板 + 通知右侧预览刷新。
  /// 仅用于按钮/开关/勾选/上传等离散操作；文本输入走 widget.onChanged()，
  /// 避免输入时重建整个左侧面板导致光标抖动。
  void _notify() {
    setState(() {});
    widget.onChanged();
  }

  // —— 各类操作 ——
  void _addMember() {
    widget.model.members.add(Member(
      id: shortId(),
      name: '新成员',
      color: randomAvatarColor(),
    ));
    _notify();
  }

  void _removeMember(Member m) {
    widget.model.members.removeWhere((x) => x.id == m.id);
    // 同步删除该成员的全部消息，避免遗留 senderId 无效消息导致 Dropdown 断言崩溃 / 预览残留
    final removed = widget.model.messages
        .where((msg) => msg.senderId == m.id)
        .toList();
    widget.model.messages.removeWhere((msg) => msg.senderId == m.id);
    for (final msg in removed) {
      _tc.remove('msg_content_${msg.id}');
      _tc.remove('msg_div_${msg.id}');
      for (final seg in msg.segments) {
        _tc.remove('sys_${msg.id}_${seg.id}');
      }
    }
    _tc.remove('m_name_${m.id}');
    _notify();
  }

  void _setMe(Member m) {
    for (final x in widget.model.members) {
      x.isMe = (x.id == m.id);
    }
    _notify();
  }

  Future<void> _uploadAvatar(Member m) async {
    final url = await pickImageAsDataUrl(isAvatar: true);
    if (!mounted) return;
    if (url != null) {
      m.avatarUrl = url;
      _notify();
    }
  }

  void _addMessage(String type) {
    final firstId = widget.model.members.isNotEmpty
        ? widget.model.members.first.id
        : null;
    widget.model.messages.add(ChatMessage(
      id: shortId(),
      type: type,
      senderId: type == 'system' || type == 'divider' ? null : firstId,
      content: '',
      segments: type == 'system'
          ? [SystemSegment(id: shortId(), text: '系统提示')]
          : const [],
      time: DateTime.now(),
    ));
    _notify();
  }

  void _removeMessage(ChatMessage m) {
    widget.model.messages.removeWhere((x) => x.id == m.id);
    _tc.remove('msg_content_${m.id}');
    _tc.remove('msg_div_${m.id}');
    for (final seg in m.segments) {
      _tc.remove('sys_${m.id}_${seg.id}');
    }
    _notify();
  }

  void _addSystemSegment(ChatMessage m) {
    m.segments.add(SystemSegment(id: shortId()));
    _notify();
  }

  void _removeSystemSegment(ChatMessage m, SystemSegment seg) {
    if (m.segments.length <= 1) return; // 至少保留一条
    m.segments.remove(seg);
    _tc.remove('sys_${m.id}_${seg.id}');
    _notify();
  }

  /// 上移(delta=-1) / 下移(delta=+1) 消息位置，越界不做任何事
  void _moveMessage(ChatMessage m, int delta) {
    final i = widget.model.messages.indexOf(m);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= widget.model.messages.length) return;
    widget.model.messages
      ..removeAt(i)
      ..insert(j, m);
    _notify();
  }

  void _loadGroup() {
    final s = sampleModel();
    widget.model
      ..isGroup = s.isGroup
      ..title = s.title
      ..showMemberCount = s.showMemberCount
      ..members.clear()
      ..members.addAll(s.members)
      ..messages.clear()
      ..messages.addAll(s.messages);
    _tc.clear();
    _notify();
  }

  void _loadSingle() {
    final s = singleChatSample();
    widget.model
      ..isGroup = s.isGroup
      ..title = s.title
      ..showMemberCount = s.showMemberCount
      ..members.clear()
      ..members.addAll(s.members)
      ..messages.clear()
      ..messages.addAll(s.messages);
    _tc.clear();
    _notify();
  }

  // —— UI 小部件 ——
  /// 当前状态栏时间的「时 / 分」段（无 time 或格式异常时留空）
  String get _timeHour {
    final parts = (widget.model.statusBarTime ?? '').split(':');
    return (parts.length == 2 && parts[0].isNotEmpty) ? parts[0] : '';
  }

  String get _timeMinute {
    final parts = (widget.model.statusBarTime ?? '').split(':');
    return (parts.length == 2 && parts[1].isNotEmpty) ? parts[1] : '';
  }

  static const TextStyle _timeInputStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static InputDecoration _timeInputDecoration(String hint) => InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        border: const OutlineInputBorder(),
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black26),
        hintText: hint,
        isDense: true,
      );

  /// 读两个数字段合成 "h:mm"；任一段为空/非法时回退实时时钟
  void _applyStatusTime() {
    final h = int.tryParse(_ctrl('status_time_h', '').text.trim());
    final m = int.tryParse(_ctrl('status_time_m', '').text.trim());
    if (h == null || m == null) {
      widget.model.statusBarTime = null;
    } else {
      widget.model.statusBarTime =
          '${h.clamp(0, 23)}:${m.clamp(0, 59).toString().padLeft(2, '0')}';
    }
    widget.onChanged();
  }

  void _setCurrentTime() {
    final now = DateTime.now();
    final h = now.hour.toString();
    final m = now.minute.toString().padLeft(2, '0');
    _ctrl('status_time_h', h).text = h;
    _ctrl('status_time_m', m).text = m;
    widget.model.statusBarTime = '$h:$m';
    _notify();
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      );

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return Container(
      color: const Color(0xFFF2F2F2),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 下载按钮
            ElevatedButton.icon(
              onPressed: widget.onDownload,
              icon: const Icon(Icons.download, size: 20),
              label: const Text('下载截图', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: WeChatTheme.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _loadGroup, child: const Text('群聊示例'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: _loadSingle, child: const Text('单聊示例'))),
              ],
            ),

            const SizedBox(height: 16),
            _sectionTitle('系统状态栏'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 系统时间：两段式数字输入（时 : 分），冒号无需手工输入，只接受数字
                  Row(
                    children: [
                      const Text('时间', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      SizedBox(
                        width: 44,
                        height: 36,
                        child: TextField(
                          controller: _ctrl('status_time_h', _timeHour),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          style: _timeInputStyle,
                          decoration: _timeInputDecoration('9'),
                          onChanged: (_) => _applyStatusTime(),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text(':', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                      ),
                      SizedBox(
                        width: 44,
                        height: 36,
                        child: TextField(
                          controller: _ctrl('status_time_m', _timeMinute),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          style: _timeInputStyle,
                          decoration: _timeInputDecoration('41'),
                          onChanged: (_) => _applyStatusTime(),
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
                  Row(
                    children: [
                      const Text('电池', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      Text('${model.batteryPercent}%',
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  Slider(
                    value: model.batteryPercent.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (v) {
                      model.batteryPercent = v.round();
                      _notify();
                    },
                  ),
                  Row(
                    children: [
                      const Text('充电中', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      Switch(
                        value: model.isCharging,
                        onChanged: (v) {
                          model.isCharging = v;
                          _notify();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('信号强度', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      DropdownButton<int>(
                        value: model.signalLevel,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 格')),
                          DropdownMenuItem(value: 2, child: Text('2 格')),
                          DropdownMenuItem(value: 3, child: Text('3 格')),
                          DropdownMenuItem(value: 4, child: Text('4 格')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            model.signalLevel = v;
                            _notify();
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('显示 WiFi', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      Switch(
                        value: model.showWifi,
                        onChanged: (v) {
                          model.showWifi = v;
                          _notify();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('电量百分比', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      Switch(
                        value: model.showBatteryPercent,
                        onChanged: (v) {
                          model.showBatteryPercent = v;
                          _notify();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _sectionTitle('聊天类型'),
            _card(
              child: ToggleButtons(
                isSelected: [!model.isGroup, model.isGroup],
                onPressed: (i) {
                  model.isGroup = (i == 1);
                  _notify();
                },
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('单聊')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('群聊')),
                ],
              ),
            ),

            _sectionTitle('标题'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                  controller: _ctrl('title', model.title),
                  onChanged: (v) {
                    model.title = v;
                    widget.onChanged();
                  },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '群名 / 联系人名',
                      isDense: true,
                    ),
                  ),
                  if (model.isGroup)
                    Row(
                      children: [
                        Checkbox(
                          value: model.showMemberCount,
                          onChanged: (v) {
                            model.showMemberCount = v ?? true;
                            _notify();
                          },
                        ),
                        const Text('标题后显示成员数 (N)'),
                      ],
                    ),
                ],
              ),
            ),

            _sectionTitle('成员（接收人 / 发送人）'),
            // 每张成员卡独立 RepaintBoundary：滚动时各卡作为已栅格化图层平移，
            // 只有真正变化/新滚入视口的卡才重绘，避免整面板每帧全量重绘卡顿。
            ...model.members.map(
                (m) => RepaintBoundary(
                  key: ValueKey('member_card_${m.id}'),
                  child: _memberCard(m),
                )),
            OutlinedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.add),
              label: const Text('添加成员'),
            ),

            const SizedBox(height: 16),
            _sectionTitle('消息'),
            // 每张消息卡独立 RepaintBoundary：滚动时各卡作为已栅格化图层平移，
            // 含图片/表情缩略图的卡只栅格化一次，不再逐帧重绘。
            ...model.messages.map(
                (m) => RepaintBoundary(
                  key: ValueKey('msg_card_${m.id}'),
                  child: _messageCard(m),
                )),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: () => _addMessage('text'), child: const Text('+ 文本')),
                OutlinedButton(onPressed: () => _addMessage('image'), child: const Text('+ 图片')),
                OutlinedButton(onPressed: () => _addMessage('sticker'), child: const Text('+ 表情')),
                OutlinedButton(onPressed: () => _addMessage('system'), child: const Text('+ 系统提示')),
                OutlinedButton(onPressed: () => _addMessage('divider'), child: const Text('+ 时间分割')),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _memberCard(Member m) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(member: m, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl('m_name_${m.id}', m.name),
                  onChanged: (v) {
                    m.name = v;
                    widget.onChanged();
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '成员名',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeMember(m),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _uploadAvatar(m),
                icon: const Icon(Icons.image, size: 16),
                label: const Text('上传头像', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Checkbox(
                    value: m.isMe,
                    onChanged: (_) => _setMe(m),
                  ),
                  const Text('设为发送人(我)'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 系统提示分段编辑器：每行 = 高亮勾选框 + 文本 + 删除（最少保留一条）
  Widget _systemSegmentsEditor(ChatMessage m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final seg in m.segments)
          Row(
            children: [
              Checkbox(
                value: seg.highlight,
                onChanged: (v) {
                  seg.highlight = v ?? false;
                  _notify();
                },
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl('sys_${m.id}_${seg.id}', seg.text),
                  onChanged: (v) {
                    seg.text = v;
                    widget.onChanged();
                  },
                  maxLines: 1,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: '片段内容',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                tooltip: '删除条目',
                onPressed: m.segments.length > 1
                    ? () => _removeSystemSegment(m, seg)
                    : null,
              ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _addSystemSegment(m),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加条目', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageCard(ChatMessage m) {
    final model = widget.model;
    final isDivider = m.type == 'divider';
    final isSystem = m.type == 'system';
    final showSender = !isSystem && !isDivider;
    final index = model.messages.indexOf(m);
    final canMoveUp = index > 0;
    final canMoveDown = index >= 0 && index < model.messages.length - 1;
    final typeLabel = {
      'text': '文本',
      'image': '图片',
      'sticker': '表情',
      'system': '系统提示',
      'divider': '时间分割',
    }[m.type]!;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButton<String>(
                value: m.type,
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('文本')),
                  DropdownMenuItem(value: 'image', child: Text('图片')),
                  DropdownMenuItem(value: 'sticker', child: Text('表情')),
                  DropdownMenuItem(value: 'system', child: Text('系统提示')),
                  DropdownMenuItem(value: 'divider', child: Text('时间分割')),
                ],
                onChanged: (v) {
                  final wasSystem = m.type == 'system';
                  m.type = v!;
                  if (v == 'system' || v == 'divider') m.senderId = null;
                  if (v == 'system' && m.segments.isEmpty) {
                    m.segments = [
                      SystemSegment(
                        id: shortId(),
                        text: m.content.trim().isEmpty ? '系统提示' : m.content,
                      ),
                    ];
                  }
                  if (wasSystem && v != 'system') {
                    m.content = m.segments.map((s) => s.text).join('');
                  }
                  if ((v == 'text' || v == 'image' || v == 'sticker') &&
                      (m.senderId == null || !model.members.any((mm) => mm.id == m.senderId))) {
                    m.senderId = model.members.isNotEmpty ? model.members.first.id : null;
                  }
                  _notify();
                },
              ),
              const SizedBox(width: 8),
              if (showSender)
                Expanded(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: m.senderId,
                    hint: const Text('发送人'),
                    items: model.members
                        .map((mm) => DropdownMenuItem(
                              value: mm.id,
                              child: Text(mm.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      m.senderId = v;
                      _notify();
                    },
                  ),
                ),
              if (canMoveUp)
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up,
                      size: 18, color: Colors.black54),
                  visualDensity: VisualDensity.compact,
                  tooltip: '上移',
                  onPressed: () => _moveMessage(m, -1),
                ),
              if (canMoveDown)
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Colors.black54),
                  visualDensity: VisualDensity.compact,
                  tooltip: '下移',
                  onPressed: () => _moveMessage(m, 1),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeMessage(m),
              ),
            ],
          ),
          if (m.type == 'system')
            _systemSegmentsEditor(m)
          else if (!isDivider)
            TextField(
              controller: _ctrl('msg_content_${m.id}', m.content),
              onChanged: (v) {
                m.content = v;
                widget.onChanged();
              },
              maxLines: m.type == 'text' ? 2 : 1,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: m.type == 'image'
                    ? '（用下方按钮上传图片）'
                    : (m.type == 'sticker' ? '（用下方按钮上传表情）' : '消息内容'),
              ),
            ),
          if (m.type == 'image' || m.type == 'sticker') ...[
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: () async {
                final url = await pickImageAsDataUrl();
                if (!mounted) return;
                if (url != null) {
                  m.content = url;
                  _notify();
                }
              },
              icon: const Icon(Icons.upload, size: 16),
              label: Text(m.type == 'sticker' ? '上传表情' : '上传图片',
                  style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            ),
            if (m.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                // 表情预览保留透明通道（contain，无裁剪、无底色）
                child: CachedMemoryImage(
                  dataUrl: m.content,
                  width: 64,
                  height: 64,
                  fit: m.type == 'sticker' ? BoxFit.contain : BoxFit.cover,
                  cacheWidth: 128,
                ),
              ),
          ],
          const SizedBox(height: 6),
          if (!isSystem) ...[
            Row(
              children: [
                Checkbox(
                  value: m.showDateDivider,
                  onChanged: (v) {
                    m.showDateDivider = v ?? false;
                    _notify();
                  },
                ),
                const Text('该条前插入时间分割线'),
              ],
            ),
            if (m.showDateDivider || isDivider)
              TextField(
                controller: _ctrl('msg_div_${m.id}', m.dateDividerText ?? ''),
                onChanged: (v) {
                  m.dateDividerText = v.isEmpty ? null : v;
                  widget.onChanged();
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: '留空=自动（如 上午 9:30）',
                ),
              ),
          ],
          const SizedBox(height: 2),
          Text('类型：$typeLabel',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
