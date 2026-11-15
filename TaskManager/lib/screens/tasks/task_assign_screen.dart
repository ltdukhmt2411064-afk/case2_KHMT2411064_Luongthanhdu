import 'package:flutter/material.dart';
import '../../services/collab_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/user_picker_sheet.dart';

// Quản lý người được giao việc. Chỉ người tạo (canManage = true) được giao thêm,
// đổi người phụ trách chính và hủy giao. Khi quay lại sẽ pop(true) nếu có thay đổi.
class TaskAssignScreen extends StatefulWidget {
  final String taskId;
  final bool canManage;

  const TaskAssignScreen({super.key, required this.taskId, required this.canManage});

  @override
  State<TaskAssignScreen> createState() => _TaskAssignScreenState();
}

class _TaskAssignScreenState extends State<TaskAssignScreen> {
  final _service = CollabService();
  AssigneeInfo? _info;
  bool _loading = true;
  bool _changed = false;
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
      final info = await _service.getAssignees(widget.taskId);
      if (!mounted) return;
      setState(() {
        _info = info;
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

  Future<void> _add() async {
    final existing = (_info?.assignees ?? []).map((u) => u.id).toSet();
    final picked = await showUserPicker(
      context,
      title: 'Giao việc cho',
      excludeIds: existing,
    );
    if (picked == null || picked.isEmpty) return;
    try {
      final info = await _service.assignUsers(
        widget.taskId,
        picked.map((u) => u.id).toList(),
      );
      _changed = true;
      if (!mounted) return;
      setState(() => _info = info);
      _showMessage('Đã giao việc cho ${picked.length} người');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _setPrimary(String userId) async {
    try {
      await _service.setPrimaryAssignee(widget.taskId, userId);
      _changed = true;
      await _load(showSpinner: false);
      _showMessage('Đã đổi người phụ trách chính');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _remove(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy giao việc'),
        content: Text('Hủy giao việc cho "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy giao'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.removeAssignee(widget.taskId, userId);
      _changed = true;
      await _load(showSpinner: false);
      _showMessage('Đã hủy giao việc');
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

    final info = _info!;
    if (info.assignees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.canManage
                ? 'Chưa giao cho ai.\nBấm "Giao thêm" để chọn người thực hiện.'
                : 'Công việc này chưa được giao cho ai.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: info.assignees.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final u = info.assignees[index];
        final isPrimary = u.id == info.primaryId;
        return ListTile(
          leading: CircleAvatar(child: Text(userInitial(u))),
          title: Row(
            children: [
              Flexible(child: Text(u.fullName, overflow: TextOverflow.ellipsis)),
              if (isPrimary) ...[
                const SizedBox(width: 8),
                LabelChip(
                  text: 'Phụ trách chính',
                  color: Colors.amber.shade800,
                  icon: Icons.star,
                ),
              ],
            ],
          ),
          subtitle: Text(u.email),
          trailing: widget.canManage
              ? PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'primary') _setPrimary(u.id);
                    if (v == 'remove') _remove(u.id, u.fullName);
                  },
                  itemBuilder: (_) => [
                    if (!isPrimary)
                      const PopupMenuItem(
                        value: 'primary',
                        child: Text('Đặt làm phụ trách chính'),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Hủy giao việc', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Người được giao')),
        body: _buildBody(),
        floatingActionButton: widget.canManage
            ? FloatingActionButton.extended(
                onPressed: _add,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Giao thêm'),
              )
            : null,
      ),
    );
  }
}
