import 'package:flutter/material.dart';
import '../../models/stats_models.dart';
import '../../models/task.dart';
import '../../services/statistics_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_widgets.dart';
import '../tasks/task_detail_screen.dart';

class StatisticsDashboardScreen extends StatefulWidget {
  const StatisticsDashboardScreen({super.key});

  @override
  State<StatisticsDashboardScreen> createState() => _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState extends State<StatisticsDashboardScreen> {
  final _service = StatisticsService();
  StatsOverview? _stats;
  List<Task> _dueSoon = [];
  List<Task> _overdue = [];
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
      final results = await Future.wait([
        _service.getOverview(),
        _service.getDueSoon(),
        _service.getOverdue(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as StatsOverview;
        _dueSoon = results[1] as List<Task>;
        _overdue = results[2] as List<Task>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openTask(Task task) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    );
    _load(showSpinner: false);
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _statusRow(String label, int count, int total, Color color) {
    final value = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('  (${(value * 100).round()}%)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, int value, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: children,
    );
  }

  Widget _taskList(List<Task> tasks) {
    return Column(
      children: tasks
          .map((t) => TaskCard(task: t, onTap: () => _openTask(t)))
          .toList(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Đang tải thống kê...');
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

    final s = _stats!;
    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            children: [
              _title('Công việc theo trạng thái (${s.total})'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _statusRow('Chưa thực hiện', s.todo, s.total, statusColor('todo')),
                      _statusRow('Đang thực hiện', s.inProgress, s.total, statusColor('in_progress')),
                      _statusRow('Đã hoàn thành', s.done, s.total, statusColor('done')),
                    ],
                  ),
                ),
              ),
              _title('Của tôi'),
              _grid([
                _statCard(Icons.edit_note, 'Tôi tạo', s.createdByMe, Colors.blue),
                _statCard(Icons.assignment_ind_outlined, 'Được giao cho tôi', s.assignedToMe, Colors.indigo),
                _statCard(Icons.star_outline, 'Tôi phụ trách chính (chưa xong)', s.primaryActive, Colors.amber.shade800),
                _statCard(Icons.share_outlined, 'Được chia sẻ', s.sharedWithMe, Colors.teal),
              ]),
              _title('Hạn hoàn thành'),
              _grid([
                _statCard(Icons.alarm, 'Sắp đến hạn (${s.dueSoonDays} ngày)', s.dueSoon, Colors.orange.shade700),
                _statCard(Icons.warning_amber_rounded, 'Đã quá hạn', s.overdue, Colors.red),
              ]),
              if (_overdue.isNotEmpty) ...[
                _title('Công việc đã quá hạn'),
                _taskList(_overdue),
              ],
              if (_dueSoon.isNotEmpty) ...[
                _title('Công việc sắp đến hạn'),
                _taskList(_dueSoon),
              ],
              if (_overdue.isEmpty && _dueSoon.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'Không có công việc nào sắp đến hạn hoặc quá hạn.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
