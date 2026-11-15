import 'task.dart';

class CollabLabels {
  static const Map<String, String> permissions = {
    'viewer': 'Chỉ xem',
    'editor': 'Được sửa',
  };

  static const Map<String, String> eventTypes = {
    'task_assigned': 'Được giao việc',
    'task_shared': 'Được chia sẻ',
    'due_date_changed': 'Đổi hạn hoàn thành',
    'task_completed': 'Hoàn thành công việc',
    'deadline_reminder': 'Nhắc sắp đến hạn',
  };

  static const Map<String, String> emailStatuses = {
    'pending': 'Đang chờ',
    'sent': 'Đã gửi',
    'failed': 'Gửi lỗi',
  };
}

DateTime? _parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

class TaskShareItem {
  final String id;
  final TaskUser user;
  final String permission;
  final String sharedByName;
  final DateTime? createdAt;

  TaskShareItem({
    required this.id,
    required this.user,
    required this.permission,
    this.sharedByName = '',
    this.createdAt,
  });

  factory TaskShareItem.fromJson(Map<String, dynamic> json) {
    final by = json['sharedBy'];
    return TaskShareItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      user: TaskUser.fromAny(json['userId']),
      permission: (json['permission'] ?? 'viewer').toString(),
      sharedByName: by is Map ? (by['fullName'] ?? '').toString() : '',
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? taskId;
  final String? taskTitle;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.taskId,
    this.taskTitle,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final t = json['taskId'];
    String? taskId;
    String? taskTitle;
    if (t is Map) {
      taskId = (t['_id'] ?? t['id'])?.toString();
      taskTitle = t['title']?.toString();
    } else if (t != null) {
      taskId = t.toString();
    }
    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: json['isRead'] == true,
      taskId: taskId,
      taskTitle: taskTitle,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        taskId: taskId,
        taskTitle: taskTitle,
        createdAt: createdAt,
      );
}

class EmailLog {
  final String id;
  final String recipientEmail;
  final String eventType;
  final String subject;
  final String status;
  final int attempts;
  final String errorMessage;
  final DateTime? sentAt;
  final DateTime? createdAt;

  EmailLog({
    required this.id,
    required this.recipientEmail,
    required this.eventType,
    required this.subject,
    required this.status,
    this.attempts = 0,
    this.errorMessage = '',
    this.sentAt,
    this.createdAt,
  });

  factory EmailLog.fromJson(Map<String, dynamic> json) {
    return EmailLog(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      recipientEmail: (json['recipientEmail'] ?? '').toString(),
      eventType: (json['eventType'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      errorMessage: (json['errorMessage'] ?? '').toString(),
      sentAt: _parseDate(json['sentAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}
