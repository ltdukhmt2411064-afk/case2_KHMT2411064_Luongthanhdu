class TaskLabels {
  static const Map<String, String> statuses = {
    'todo': 'Chưa thực hiện',
    'in_progress': 'Đang thực hiện',
    'done': 'Đã hoàn thành',
  };

  static const Map<String, String> priorities = {
    'low': 'Thấp',
    'medium': 'Trung bình',
    'high': 'Cao',
  };

  static const Map<String, String> roles = {
    'owner': 'Người tạo',
    'assignee': 'Được giao',
    'editor': 'Được chia sẻ (sửa)',
    'viewer': 'Được chia sẻ (xem)',
  };
}

class TaskUser {
  final String id;
  final String fullName;
  final String email;
  final String avatarUrl;

  TaskUser({
    required this.id,
    required this.fullName,
    this.email = '',
    this.avatarUrl = '',
  });

  // Backend có thể trả về object đã populate hoặc chỉ là chuỗi id
  factory TaskUser.fromAny(dynamic value) {
    if (value is Map) {
      return TaskUser(
        id: (value['_id'] ?? value['id'] ?? '').toString(),
        fullName: (value['fullName'] ?? '').toString(),
        email: (value['email'] ?? '').toString(),
        avatarUrl: (value['avatarUrl'] ?? '').toString(),
      );
    }
    return TaskUser(id: value?.toString() ?? '', fullName: '');
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskUser createdBy;
  final List<TaskUser> assignees;
  final String? primaryAssigneeId;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final String myRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdBy,
    this.assignees = const [],
    this.primaryAssigneeId,
    this.startDate,
    this.dueDate,
    this.priority = 'medium',
    this.status = 'todo',
    this.myRole = 'owner',
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    final primary = json['primaryAssigneeId'];
    String? primaryId;
    if (primary is Map) {
      primaryId = (primary['_id'] ?? primary['id'])?.toString();
    } else if (primary != null) {
      primaryId = primary.toString();
    }

    return Task(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdBy: TaskUser.fromAny(json['createdBy']),
      assignees: ((json['assigneeIds'] as List?) ?? [])
          .map((e) => TaskUser.fromAny(e))
          .toList(),
      primaryAssigneeId: primaryId,
      startDate: parseDate(json['startDate']),
      dueDate: parseDate(json['dueDate']),
      priority: (json['priority'] ?? 'medium').toString(),
      status: (json['status'] ?? 'todo').toString(),
      myRole: (json['myRole'] ?? 'owner').toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  bool get isOverdue =>
      dueDate != null && status != 'done' && dueDate!.isBefore(DateTime.now());

  // owner và editor được sửa mọi trường
  bool get canEdit => myRole == 'owner' || myRole == 'editor';

  // owner, editor, assignee được đổi trạng thái
  bool get canChangeStatus => myRole != 'viewer';

  bool get canDelete => myRole == 'owner';
}
