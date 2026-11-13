import '../models/task.dart';
import 'api_client.dart';

class TaskListResult {
  final List<Task> tasks;
  final int total;

  TaskListResult({required this.tasks, required this.total});
}

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  final ApiClient _api = ApiClient();

  Future<TaskListResult> getTasks({
    String role = 'all',
    String? status,
    String? priority,
    String? search,
    String sortBy = 'createdAt',
    String order = 'desc',
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'role': role,
      'sortBy': sortBy,
      'order': order,
      'page': '$page',
      'limit': '$limit',
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (priority != null && priority.isNotEmpty) params['priority'] = priority;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    final query = Uri(queryParameters: params).query;
    final response = await _api.get('/tasks?$query');

    final list = (response['data']['tasks'] as List)
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return TaskListResult(
      tasks: list,
      total: (response['total'] as num?)?.toInt() ?? list.length,
    );
  }

  Future<Task> getTask(String id) async {
    final response = await _api.get('/tasks/$id');
    return Task.fromJson(Map<String, dynamic>.from(response['data']['task'] as Map));
  }

  Future<Task> createTask({
    required String title,
    String description = '',
    DateTime? startDate,
    DateTime? dueDate,
    String priority = 'medium',
    String status = 'todo',
  }) async {
    final response = await _api.post('/tasks', body: {
      'title': title.trim(),
      'description': description.trim(),
      'startDate': startDate?.toUtc().toIso8601String(),
      'dueDate': dueDate?.toUtc().toIso8601String(),
      'priority': priority,
      'status': status,
    });
    return Task.fromJson(Map<String, dynamic>.from(response['data']['task'] as Map));
  }

  // Gửi đủ các trường; startDate/dueDate = null nghĩa là xóa ngày
  Future<Task> updateTask(
    String id, {
    required String title,
    String description = '',
    DateTime? startDate,
    DateTime? dueDate,
    required String priority,
    required String status,
  }) async {
    final response = await _api.put('/tasks/$id', body: {
      'title': title.trim(),
      'description': description.trim(),
      'startDate': startDate?.toUtc().toIso8601String(),
      'dueDate': dueDate?.toUtc().toIso8601String(),
      'priority': priority,
      'status': status,
    });
    return Task.fromJson(Map<String, dynamic>.from(response['data']['task'] as Map));
  }

  Future<void> updateStatus(String id, String status) async {
    await _api.patch('/tasks/$id/status', body: {'status': status});
  }

  Future<void> deleteTask(String id) async {
    await _api.delete('/tasks/$id');
  }
}
