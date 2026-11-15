import '../models/stats_models.dart';
import '../models/task.dart';
import 'api_client.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final ApiClient _api = ApiClient();

  Future<StatsOverview> getOverview({int days = 3}) async {
    final res = await _api.get('/statistics/overview?days=$days');
    return StatsOverview.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  List<Task> _tasks(dynamic res) {
    return ((res['data']['tasks'] as List?) ?? [])
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Task>> getDueSoon({int days = 3}) async {
    final res = await _api.get('/statistics/due-soon?days=$days');
    return _tasks(res);
  }

  Future<List<Task>> getOverdue() async {
    final res = await _api.get('/statistics/overdue');
    return _tasks(res);
  }

  Future<List<ActivityItem>> getActivities(String taskId) async {
    final res = await _api.get('/tasks/$taskId/activities');
    return ((res['data']['activities'] as List?) ?? [])
        .map((e) => ActivityItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
