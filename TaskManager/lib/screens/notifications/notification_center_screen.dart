import 'package:flutter/material.dart';
import '../../models/collaboration.dart';
import '../../services/collab_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../tasks/task_detail_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _service = CollabService();
  List<AppNotification> _items = [];
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
      final items = await _service.getNotifications();
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

  int get _unread => _items.where((n) => !n.isRead).length;

  IconData _iconFor(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_ind_outlined;
      case 'task_shared':
        return Icons.share_outlined;
      case 'due_date_changed':
        return Icons.event_repeat_outlined;
      case 'task_completed':
        return Icons.check_circle_outline;
      case 'deadline_reminder':
        return Icons.alarm;
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _items.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      // Cập nhật giao diện ngay, gọi API ở nền
      setState(() {
        _items = _items.map((x) => x.id == n.id ? x.copyWith(isRead: true) : x).toList();
      });
      try {
        await _service.markRead(n.id);
      } catch (_) {}
    }
    if (n.taskId == null || !mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: n.taskId!)),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Đang tải thông báo...');
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
          Icon(Icons.notifications_none, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text('Chưa có thông báo nào.', style: TextStyle(color: Colors.grey)),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final n = _items[index];
        final primary = Theme.of(context).colorScheme.primary;
        return ListTile(
          tileColor: n.isRead ? null : primary.withValues(alpha: 0.06),
          leading: CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.12),
            child: Icon(_iconFor(n.type), color: primary),
          ),
          title: Text(
            n.title,
            style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.message),
              const SizedBox(height: 2),
              Text(
                DateFormatter.formatDateTime(n.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: n.isRead
              ? null
              : const Icon(Icons.circle, size: 10, color: Colors.redAccent),
          onTap: () => _open(n),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_unread > 0 ? 'Thông báo ($_unread chưa đọc)' : 'Thông báo'),
        actions: [
          if (_unread > 0)
            TextButton(onPressed: _markAllRead, child: const Text('Đọc tất cả')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(showSpinner: false),
        child: _buildBody(),
      ),
    );
  }
}
