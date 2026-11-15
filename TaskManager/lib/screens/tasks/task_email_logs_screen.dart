import 'package:flutter/material.dart';
import '../../models/collaboration.dart';
import '../../services/collab_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_widgets.dart';

// Lịch sử gửi email của một công việc (chỉ người tạo xem được). Có nút gửi lại khi lỗi.
class TaskEmailLogsScreen extends StatefulWidget {
  final String taskId;

  const TaskEmailLogsScreen({super.key, required this.taskId});

  @override
  State<TaskEmailLogsScreen> createState() => _TaskEmailLogsScreenState();
}

class _TaskEmailLogsScreenState extends State<TaskEmailLogsScreen> {
  final _service = CollabService();
  List<EmailLog> _logs = [];
  bool _loading = true;
  String? _error;
  String? _retryingId;

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
      final logs = await _service.getEmailLogs(widget.taskId);
      if (!mounted) return;
      setState(() {
        _logs = logs;
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

  Future<void> _retry(EmailLog log) async {
    setState(() => _retryingId = log.id);
    String message;
    try {
      await _service.retryEmail(log.id);
      message = 'Đã thử gửi lại email';
    } catch (e) {
      message = e.toString();
    }
    if (!mounted) return;
    setState(() => _retryingId = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _load(showSpinner: false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.green.shade600;
      case 'failed':
        return Colors.red.shade600;
      default:
        return Colors.blueGrey;
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
    if (_logs.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.mail_outline, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Chưa có email nào được gửi\ncho công việc này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _logs[index];
        final color = _statusColor(log.status);
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.subject,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    LabelChip(
                      text: CollabLabels.emailStatuses[log.status] ?? log.status,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Đến: ${log.recipientEmail}'),
                Text(
                  'Sự kiện: ${CollabLabels.eventTypes[log.eventType] ?? log.eventType}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                Text(
                  'Số lần thử: ${log.attempts}'
                  '${log.sentAt != null ? '  •  Gửi lúc ${DateFormatter.formatDateTime(log.sentAt)}' : ''}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                if (log.status == 'failed' && log.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lỗi: ${log.errorMessage}',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                if (log.status == 'failed') ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _retryingId == log.id ? null : () => _retry(log),
                      icon: _retryingId == log.id
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text('Gửi lại'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử email')),
      body: RefreshIndicator(
        onRefresh: () => _load(showSpinner: false),
        child: _buildBody(),
      ),
    );
  }
}
