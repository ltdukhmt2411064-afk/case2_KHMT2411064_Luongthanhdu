import 'package:flutter/material.dart';
import '../../models/collaboration.dart';
import '../../services/collab_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/user_picker_sheet.dart';

// Quản lý chia sẻ công việc (viewer / editor). Chỉ người tạo (canManage) được
// chia sẻ thêm, đổi quyền và thu hồi.
class TaskShareScreen extends StatefulWidget {
  final String taskId;
  final bool canManage;

  const TaskShareScreen({super.key, required this.taskId, required this.canManage});

  @override
  State<TaskShareScreen> createState() => _TaskShareScreenState();
}

class _TaskShareScreenState extends State<TaskShareScreen> {
  final _service = CollabService();
  List<TaskShareItem> _shares = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final shares = await _service.getShares(widget.taskId);
      if (!mounted) return;
      setState(() {
        _shares = shares;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _askPermission() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Chọn quyền chia sẻ'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'viewer'),
            child: const Text('Chỉ xem (viewer)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'editor'),
            child: const Text('Được chỉnh sửa (editor)'),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final existing = _shares.map((s) => s.user.id).toSet();
    final picked = await showUserPicker(
      context,
      title: 'Chia sẻ công việc cho',
      excludeIds: existing,
    );
    if (picked == null || picked.isEmpty) return;
    final permission = await _askPermission();
    if (permission == null) return;
    try {
      await _service.shareTask(widget.taskId, picked.map((u) => u.id).toList(), permission);
      await _load(showSpinner: false);
      _showMessage('Đã chia sẻ cho ${picked.length} người');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _changePermission(TaskShareItem s, String permission) async {
    if (permission == s.permission) return;
    try {
      await _service.updateSharePermission(widget.taskId, s.id, permission);
      await _load(showSpinner: false);
      _showMessage('Đã đổi quyền');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _revoke(TaskShareItem s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi chia sẻ'),
        content: Text('Thu hồi quyền truy cập của "${s.user.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.revokeShare(widget.taskId, s.id);
      await _load(showSpinner: false);
      _showMessage('Đã thu hồi chia sẻ');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_shares.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.canManage
                ? 'Chưa chia sẻ cho ai.\nBấm "Chia sẻ thêm" để bắt đầu.'
                : 'Công việc này chưa được chia sẻ cho ai.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _shares.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = _shares[index];
          final isEditor = s.permission == 'editor';
          return ListTile(
            leading: CircleAvatar(child: Text(userInitial(s.user))),
            title: Row(
              children: [
                Flexible(child: Text(s.user.fullName, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                LabelChip(
                  text: CollabLabels.permissions[s.permission] ?? s.permission,
                  color: isEditor ? Colors.indigo : Colors.teal,
                  icon: isEditor ? Icons.edit_outlined : Icons.visibility_outlined,
                ),
              ],
            ),
            subtitle: Text(s.user.email),
            trailing: widget.canManage
                ? PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'revoke') {
                        _revoke(s);
                      } else {
                        _changePermission(s, v);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'viewer', child: Text('Đổi thành: Chỉ xem')),
                      PopupMenuItem(value: 'editor', child: Text('Đổi thành: Được sửa')),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'revoke',
                        child: Text('Thu hồi', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ công việc')),
      body: _buildBody(),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Chia sẻ thêm'),
            )
          : null,
    );
  }
}
