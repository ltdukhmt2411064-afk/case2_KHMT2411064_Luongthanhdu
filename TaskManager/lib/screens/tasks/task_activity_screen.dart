import 'package:flutter/material.dart';
import '../../models/stats_models.dart';
import '../../services/statistics_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';

// Lịch sử hoạt động của một công việc (ai làm gì, lúc nào)
class TaskActivityScreen extends StatefulWidget {
  final String taskId;

  const TaskActivityScreen({super.key, required this.taskId});

  @override
  State<TaskActivityScreen> createState() => _TaskActivityScreenState();
}

class _TaskActivityScreenState extends State<TaskActivityScreen> {
  final _service = StatisticsService();
  List<ActivityItem> _items = [];
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
      final items = await _service.getActivities(widget.taskId);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  IconData _iconFor(String action) {
    switch (action) {
      case 'task_created':
        return Icons.add_circle_outline;
      case 'task_updated':
        return Icons.edit_outlined;
      case 'status_changed':
        return Icons.swap_horiz;
      case 'task_deleted':
        return Icons.delete_outline;
      case 'assignees_added':
        return Icons.person_add_alt_1_outlined;
      case 'primary_assignee_changed':
        return Icons.star_outline;
      case 'assignee_removed':
        return Icons.person_remove_outlined;
      case 'task_shared':
        return Icons.share_outlined;
      case 'share_permission_changed':
        return Icons.admin_panel_settings_outlined;
      case 'share_revoked':
        return Icons.link_off;
      default:
        return Icons.history;
    }
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Đang tải lịch sử...');
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
    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.history, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Chưa có hoạt động nào được ghi lại.\n(Chỉ ghi các thao tác từ khi bật tính năng này.)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final a = _items[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.12),
            child: Icon(_iconFor(a.action), color: primary),
          ),
          title: Text(
            ActivityLabels.actions[a.action] ?? a.action,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.details.isNotEmpty) Text(a.details),
              const SizedBox(height: 2),
              Text(
                '${a.userName.isEmpty ? 'Ai đó' : a.userName}  •  ${DateFormatter.formatDateTime(a.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          isThreeLine: a.details.isNotEmpty,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử hoạt động')),
      body: RefreshIndicator(
        onRefresh: () => _load(showSpinner: false),
        child: _buildBody(),
      ),
    );
  }
}
