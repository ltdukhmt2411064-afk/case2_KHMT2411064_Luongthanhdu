import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_widgets.dart';
import 'task_form_screen.dart';

// Khi quay lại sẽ pop(true) nếu công việc có thay đổi/bị xóa, để danh sách tải lại.
class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _taskService = TaskService();
  Task? _task;
  bool _isLoading = true;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final task = await _taskService.getTask(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeStatus(String status) async {
    final task = _task;
    if (task == null || status == task.status) return;
    try {
      await _taskService.updateStatus(task.id, status);
      _changed = true;
      await _load();
      _showMessage('Đã cập nhật trạng thái');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _edit() async {
    final task = _task;
    if (task == null) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
    if (saved == true) {
      _changed = true;
      _load();
    }
  }

  Future<void> _delete() async {
    final task = _task;
    if (task == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text('Bạn có chắc muốn xóa "${task.title}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _taskService.deleteTask(task.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Widget _infoRow(IconData icon, String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _buildContent(Task task) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              task.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatusChip(status: task.status),
                PriorityChip(priority: task.priority),
                if (task.isOverdue)
                  const LabelChip(
                    text: 'Quá hạn',
                    color: Colors.red,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.person_outline,
                      'Người tạo',
                      Text(task.createdBy.fullName.isEmpty ? '—' : task.createdBy.fullName),
                    ),
                    _infoRow(
                      Icons.verified_user_outlined,
                      'Vai trò của bạn',
                      Text(TaskLabels.roles[task.myRole] ?? task.myRole),
                    ),
                    _infoRow(
                      Icons.play_arrow_outlined,
                      'Bắt đầu',
                      Text(task.startDate == null
                          ? 'Chưa đặt'
                          : DateFormatter.formatDate(task.startDate)),
                    ),
                    _infoRow(
                      Icons.event_outlined,
                      'Hạn hoàn thành',
                      Text(
                        task.dueDate == null
                            ? 'Chưa đặt'
                            : DateFormatter.formatDate(task.dueDate),
                        style: TextStyle(color: task.isOverdue ? Colors.red : null),
                      ),
                    ),
                    _infoRow(
                      Icons.group_outlined,
                      'Người được giao',
                      Text(task.assignees.isEmpty
                          ? 'Chưa giao cho ai'
                          : task.assignees.map((u) => u.fullName).join(', ')),
                    ),
                    _infoRow(
                      Icons.schedule,
                      'Tạo lúc',
                      Text(DateFormatter.formatDateTime(task.createdAt)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              task.description.isEmpty ? 'Không có mô tả.' : task.description,
              style: TextStyle(
                color: task.description.isEmpty ? Colors.grey : null,
                height: 1.4,
              ),
            ),
            if (task.canChangeStatus) ...[
              const SizedBox(height: 20),
              const Text('Đổi trạng thái', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskLabels.statuses.entries.map((e) {
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: task.status == e.key,
                    onSelected: (_) => _changeStatus(e.key),
                  );
                }).toList(),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Bạn chỉ có quyền xem công việc này.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết công việc'),
          actions: [
            if (task != null && task.canEdit)
              IconButton(
                tooltip: 'Chỉnh sửa',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _edit,
              ),
            if (task != null && task.canDelete)
              IconButton(
                tooltip: 'Xóa',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _delete,
              ),
          ],
        ),
        body: _isLoading
            ? const LoadingView()
            : _error != null
                ? Center(
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
                  )
                : _buildContent(task!),
      ),
    );
  }
}
