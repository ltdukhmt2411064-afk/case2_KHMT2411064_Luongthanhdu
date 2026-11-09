class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ email';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ (ví dụ: name@example.com)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận lại mật khẩu';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }
}
