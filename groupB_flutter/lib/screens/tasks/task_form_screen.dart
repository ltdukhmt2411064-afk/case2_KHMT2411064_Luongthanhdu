import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';

// Thêm mới: TaskFormScreen()   |   Chỉnh sửa: TaskFormScreen(task: task)
// Khi lưu thành công sẽ pop(true) để màn trước tải lại dữ liệu.
class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = TaskService();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  late String _priority;
  late String _status;
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isSaving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? 'medium';
    _status = t?.status ?? 'todo';
    _startDate = t?.startDate?.toLocal();
    _dueDate = t?.dueDate?.toLocal();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _dueDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null && _dueDate != null && _dueDate!.isBefore(_startDate!)) {
      _showMessage('Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await _taskService.updateTask(
          widget.task!.id,
          title: _titleController.text,
          description: _descController.text,
          startDate: _startDate,
          dueDate: _dueDate,
          priority: _priority,
          status: _status,
        );
      } else {
        await _taskService.createTask(
          title: _titleController.text,
          description: _descController.text,
          startDate: _startDate,
          dueDate: _dueDate,
          priority: _priority,
          status: _status,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required bool isStart,
  }) {
    return InkWell(
      onTap: () => _pickDate(isStart: isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event),
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'Xóa ngày',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    if (isStart) {
                      _startDate = null;
                    } else {
                      _dueDate = null;
                    }
                  }),
                ),
        ),
        child: Text(
          value == null ? 'Chưa chọn' : DateFormatter.formatDate(value),
          style: TextStyle(color: value == null ? Colors.grey : null),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Chỉnh sửa công việc' : 'Thêm công việc')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Tên công việc *',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập tên công việc'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _dateField(
                          label: 'Ngày bắt đầu',
                          value: _startDate,
                          isStart: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateField(
                          label: 'Hạn hoàn thành',
                          value: _dueDate,
                          isStart: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Mức ưu tiên',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: TaskLabels.priorities.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _priority = v ?? _priority),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      prefixIcon: Icon(Icons.timelapse),
                    ),
                    items: TaskLabels.statuses.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdit ? 'LƯU THAY ĐỔI' : 'TẠO CÔNG VIỆC'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
