import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<User?> getCachedUser() async {
    if (_currentUser != null) return _currentUser;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(AppConstants.keyUserData);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        _currentUser = User.fromJson(jsonDecode(jsonStr));
        return _currentUser;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _saveUserLocally(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? avatarUrl,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
          'avatarUrl': avatarUrl.trim(),
      },
      requiresAuth: false,
    );

    final data = response['data'];
    final token = data['token'] as String;
    final user = User.fromJson(data['user']);

    await _apiClient.setToken(token);
    await _saveUserLocally(user);

    return {
      'user': user,
      'token': token,
      'message': response['message'] ?? 'Đăng ký thành công',
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
      requiresAuth: false,
    );

    final data = response['data'];
    final token = data['token'] as String;
    final user = User.fromJson(data['user']);

    await _apiClient.setToken(token);
    await _saveUserLocally(user);

    return {
      'user': user,
      'token': token,
      'message': response['message'] ?? 'Đăng nhập thành công',
    };
  }

  Future<User> getMe() async {
    final response = await _apiClient.get('/auth/me');
    final user = User.fromJson(response['data']['user']);
    await _saveUserLocally(user);
    return user;
  }

  Future<User> updateMe({String? fullName, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName.trim();
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl.trim();

    final response = await _apiClient.put('/auth/me', body: body);
    final user = User.fromJson(response['data']['user']);
    await _saveUserLocally(user);
    return user;
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.put(
      '/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return response['message'] ?? 'Đổi mật khẩu thành công';
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    _currentUser = null;
    await _apiClient.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserData);
  }
}
