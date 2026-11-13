import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_widgets.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _taskService = TaskService();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Task> _tasks = [];
  int _total = 0;
  bool _isLoading = true;
  String? _error;

  String _role = 'all';
  String? _status;
  String? _priority;
  String _sortBy = 'createdAt';
  String _order = 'desc';

  static const _roleOptions = {
    'all': 'Tất cả',
    'created': 'Tôi tạo',
    'assigned': 'Được giao',
    'shared': 'Được chia sẻ',
  };

  static const _sortOptions = {
    'createdAt': 'Ngày tạo',
    'dueDate': 'Hạn hoàn thành',
    'priority': 'Mức ưu tiên',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final result = await _taskService.getTasks(
        role: _role,
        status: _status,
        priority: _priority,
        search: _searchController.text,
        sortBy: _sortBy,
        order: _order,
      );
      if (!mounted) return;
      setState(() {
        _tasks = result.tasks;
        _total = result.total;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _openDetail(Task task) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    );
    if (changed == true) _load(showSpinner: false);
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên công việc...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _load();
                      },
                    ),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _roleOptions.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: _role == e.key,
                  onSelected: (_) {
                    setState(() => _role = e.key);
                    _load();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _dropdown<String?>(
                hint: 'Trạng thái',
                value: _status,
                items: {null: 'Mọi trạng thái', ...TaskLabels.statuses},
                onChanged: (v) {
                  setState(() => _status = v);
                  _load();
                },
              ),
              const SizedBox(width: 8),
              _dropdown<String?>(
                hint: 'Ưu tiên',
                value: _priority,
                items: {null: 'Mọi mức ưu tiên', ...TaskLabels.priorities},
                onChanged: (v) {
                  setState(() => _priority = v);
                  _load();
                },
              ),
              const SizedBox(width: 8),
              _dropdown<String>(
                hint: 'Sắp xếp',
                value: _sortBy,
                items: _sortOptions,
                onChanged: (v) {
                  setState(() => _sortBy = v ?? 'createdAt');
                  _load();
                },
              ),
              IconButton(
                tooltip: _order == 'asc' ? 'Tăng dần' : 'Giảm dần',
                icon: Icon(_order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() => _order = _order == 'asc' ? 'desc' : 'asc');
                  _load();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _dropdown<T>({
    required String hint,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint),
          isDense: true,
          items: items.entries
              .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingView(message: 'Đang tải công việc...');

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Chưa có công việc nào.\nBấm "Thêm công việc" để bắt đầu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 90),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return TaskCard(task: task, onTap: () => _openDetail(task));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Công việc' : 'Công việc ($_total)'),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ cá nhân',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(showSpinner: false),
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
      ),
    );
  }
}
