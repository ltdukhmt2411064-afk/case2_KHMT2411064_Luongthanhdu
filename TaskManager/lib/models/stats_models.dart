class StatsOverview {
  final int total;
  final int todo;
  final int inProgress;
  final int done;
  final int createdByMe;
  final int assignedToMe;
  final int primaryActive;
  final int sharedWithMe;
  final int dueSoon;
  final int overdue;
  final int dueSoonDays;

  StatsOverview({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.createdByMe,
    required this.assignedToMe,
    required this.primaryActive,
    required this.sharedWithMe,
    required this.dueSoon,
    required this.overdue,
    required this.dueSoonDays,
  });

  factory StatsOverview.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    final by = (json['byStatus'] as Map?) ?? {};
    return StatsOverview(
      total: n(json['total']),
      todo: n(by['todo']),
      inProgress: n(by['in_progress']),
      done: n(by['done']),
      createdByMe: n(json['createdByMe']),
      assignedToMe: n(json['assignedToMe']),
      primaryActive: n(json['primaryActive']),
      sharedWithMe: n(json['sharedWithMe']),
      dueSoon: n(json['dueSoon']),
      overdue: n(json['overdue']),
      dueSoonDays: n(json['dueSoonDays']) == 0 ? 3 : n(json['dueSoonDays']),
    );
  }
}

class ActivityItem {
  final String id;
  final String action;
  final String details;
  final String userName;
  final DateTime? createdAt;

  ActivityItem({
    required this.id,
    required this.action,
    required this.details,
    required this.userName,
    this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    return ActivityItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      userName: user is Map ? (user['fullName'] ?? '').toString() : '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}

class ActivityLabels {
  static const Map<String, String> actions = {
    'task_created': 'Tạo công việc',
    'task_updated': 'Cập nhật công việc',
    'status_changed': 'Đổi trạng thái',
    'task_deleted': 'Xóa công việc',
    'assignees_added': 'Giao việc',
    'primary_assignee_changed': 'Đổi người phụ trách chính',
    'assignee_removed': 'Hủy giao việc',
    'task_shared': 'Chia sẻ công việc',
    'share_permission_changed': 'Đổi quyền chia sẻ',
    'share_revoked': 'Thu hồi chia sẻ',
  };
}
