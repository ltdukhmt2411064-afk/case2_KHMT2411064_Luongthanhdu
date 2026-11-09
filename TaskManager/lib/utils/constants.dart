import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Task Manager';
  static const String appVersion = '1.0.0';

  // SharedPreferences Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'user_data';
  static const String keyBaseUrl = 'custom_base_url';

  // Mặc định Base URL thông minh theo nền tảng
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    try {
      if (Platform.isAndroid) {
        // Địa chỉ loopback của Android Emulator trỏ về máy host
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }
}
