import 'package:flutter/material.dart';
import '../chat_models.dart';
import '../wechat_theme.dart';
import '../utils.dart';
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

  // —— 各类操作 ——
  void _addMember() {
    widget.model.members.add(Member(
      id: shortId(),
      name: '新成员',
      color: randomAvatarColor(),
    ));
    widget.onChanged();
  }

  void _removeMember(Member m) {
    widget.model.members.removeWhere((x) => x.id == m.id);
    _tc.remove('m_name_${m.id}');
    widget.onChanged();
  }

  void _setMe(Member m) {
    for (final x in widget.model.members) {
      x.isMe = (x.id == m.id);
    }
    widget.onChanged();
  }

  Future<void> _uploadAvatar(Member m) async {
    final url = await pickImageAsDataUrl();
    if (url != null) {
      m.avatarUrl = url;
      widget.onChanged();
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
      content: type == 'system' ? '系统提示内容' : '',
      time: DateTime.now(),
    ));
    widget.onChanged();
  }

  void _removeMessage(ChatMessage m) {
    widget.model.messages.removeWhere((x) => x.id == m.id);
    _tc.remove('msg_content_${m.id}');
    _tc.remove('msg_div_${m.id}');
    widget.onChanged();
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
    widget.onChanged();
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
    widget.onChanged();
  }

  // —— UI 小部件 ——
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
            _sectionTitle('聊天类型'),
            _card(
              child: ToggleButtons(
                isSelected: [!model.isGroup, model.isGroup],
                onPressed: (i) {
                  model.isGroup = (i == 1);
                  widget.onChanged();
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
                            widget.onChanged();
                          },
                        ),
                        const Text('标题后显示成员数 (N)'),
                      ],
                    ),
                ],
              ),
            ),

            _sectionTitle('成员（接收人 / 发送人）'),
            ...model.members.map((m) => _memberCard(m)),
            OutlinedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.add),
              label: const Text('添加成员'),
            ),

            const SizedBox(height: 16),
            _sectionTitle('消息'),
            ...model.messages.map((m) => _messageCard(m)),
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

  Widget _messageCard(ChatMessage m) {
    final model = widget.model;
    final isDivider = m.type == 'divider';
    final isSystem = m.type == 'system';
    final showSender = !isSystem && !isDivider;
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
                  m.type = v!;
                  if (v == 'system' || v == 'divider') m.senderId = null;
                  if ((v == 'text' || v == 'image' || v == 'sticker') &&
                      (m.senderId == null || !model.members.any((mm) => mm.id == m.senderId))) {
                    m.senderId = model.members.isNotEmpty ? model.members.first.id : null;
                  }
                  widget.onChanged();
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
                      widget.onChanged();
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeMessage(m),
              ),
            ],
          ),
          if (!isDivider)
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
                hintText: isSystem
                    ? '系统提示文字'
                    : (m.type == 'image'
                        ? '（用下方按钮上传图片）'
                        : (m.type == 'sticker' ? '（用下方按钮上传表情）' : '消息内容')),
              ),
            ),
          if (m.type == 'image' || m.type == 'sticker') ...[
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: () async {
                final url = await pickImageAsDataUrl();
                if (url != null) {
                  m.content = url;
                  widget.onChanged();
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
                child: Image.network(
                  m.content,
                  width: 64,
                  height: 64,
                  fit: m.type == 'sticker' ? BoxFit.contain : BoxFit.cover,
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
                    widget.onChanged();
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
