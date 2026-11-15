import '../models/collaboration.dart';
import '../models/task.dart';
import 'api_client.dart';

class AssigneeInfo {
  final List<TaskUser> assignees;
  final String? primaryId;

  AssigneeInfo({required this.assignees, this.primaryId});
}

// Gom các API của nhóm C (giao việc, chia sẻ) và nhóm D (thông báo, email)
class CollabService {
  static final CollabService _instance = CollabService._internal();
  factory CollabService() => _instance;
  CollabService._internal();

  final ApiClient _api = ApiClient();

  List<TaskUser> _users(dynamic list) =>
      ((list as List?) ?? []).map((e) => TaskUser.fromAny(e)).toList();

  // ---------- Tìm người dùng ----------
  Future<List<TaskUser>> searchUsers(String q) async {
    final res = await _api.get('/users/search?q=${Uri.encodeQueryComponent(q.trim())}');
    return _users(res['data']['users']);
  }

  // ---------- Giao việc ----------
  AssigneeInfo _assigneeInfo(dynamic data) {
    final primary = data['primaryAssignee'];
    String? primaryId;
    if (primary is Map) {
      primaryId = (primary['_id'] ?? primary['id'])?.toString();
    } else if (primary != null) {
      primaryId = primary.toString();
    }
    return AssigneeInfo(assignees: _users(data['assignees']), primaryId: primaryId);
  }

  Future<AssigneeInfo> getAssignees(String taskId) async {
    final res = await _api.get('/tasks/$taskId/assignees');
    return _assigneeInfo(res['data']);
  }

  Future<AssigneeInfo> assignUsers(String taskId, List<String> userIds,
      {String? primaryId}) async {
    final res = await _api.post('/tasks/$taskId/assignees', body: {
      'userIds': userIds,
      if (primaryId != null) 'primaryAssigneeId': primaryId,
    });
    return _assigneeInfo(res['data']);
  }

  Future<void> setPrimaryAssignee(String taskId, String userId) async {
    await _api.patch('/tasks/$taskId/assignees/$userId');
  }

  Future<void> removeAssignee(String taskId, String userId) async {
    await _api.delete('/tasks/$taskId/assignees/$userId');
  }

  // ---------- Chia sẻ ----------
  Future<List<TaskShareItem>> getShares(String taskId) async {
    final res = await _api.get('/tasks/$taskId/shares');
    return ((res['data']['shares'] as List?) ?? [])
        .map((e) => TaskShareItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> shareTask(String taskId, List<String> userIds, String permission) async {
    await _api.post('/tasks/$taskId/shares',
        body: {'userIds': userIds, 'permission': permission});
  }

  Future<void> updateSharePermission(String taskId, String shareId, String permission) async {
    await _api.patch('/tasks/$taskId/shares/$shareId', body: {'permission': permission});
  }

  Future<void> revokeShare(String taskId, String shareId) async {
    await _api.delete('/tasks/$taskId/shares/$shareId');
  }

  // ---------- Thông báo ----------
  Future<List<AppNotification>> getNotifications() async {
    final res = await _api.get('/notifications');
    return ((res['data']['notifications'] as List?) ?? [])
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<int> unreadCount() async {
    final res = await _api.get('/notifications/unread-count');
    return (res['data']['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all');
  }

  // ---------- Lịch sử email ----------
  Future<List<EmailLog>> getEmailLogs(String taskId) async {
    final res = await _api.get('/tasks/$taskId/email-logs');
    return ((res['data']['emailLogs'] as List?) ?? [])
        .map((e) => EmailLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> retryEmail(String logId) async {
    await _api.post('/email-logs/$logId/retry');
  }
}
