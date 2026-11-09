import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/loading_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getMe();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Thử dùng cache nếu offline hoặc lỗi mạng
      final cached = await _authService.getCachedUser();
      if (mounted) {
        setState(() {
          _user = cached;
          _isLoading = false;
          if (cached == null) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  void _showEditProfileDialog() {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.fullName);
    final avatarController = TextEditingController(text: _user!.avatarUrl);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cập nhật hồ sơ cá nhân'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateFullName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: avatarController,
                    decoration: const InputDecoration(
                      labelText: 'URL Ảnh đại diện',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() => isSaving = true);

                      try {
                        final updated = await _authService.updateMe(
                          fullName: nameController.text,
                          avatarUrl: avatarController.text,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          setState(() => _user = updated);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Cập nhật hồ sơ thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureCurrent = !obscureCurrent;
                          });
                        },
                      ),
                    ),
                    validator: (v) => Validators.validateRequired(
                        v, 'Mật khẩu hiện tại'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (v) => Validators.validateConfirmPassword(
                      v,
                      newPasswordController.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() => isSaving = true);

                      try {
                        final msg = await _authService.changePassword(
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'Đang tải thông tin hồ sơ...'),
      );
    }

    if (_errorMessage != null && _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadUserProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _authService.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Quay lại Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadUserProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blueAccent.shade100,
                          backgroundImage: user.avatarUrl.isNotEmpty
                              ? NetworkImage(user.avatarUrl)
                              : null,
                          child: user.avatarUrl.isEmpty
                              ? Text(
                                  user.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                        if (user.createdAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tham gia ngày: ${DateFormatter.formatDateTime(user.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions Section
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                        title: const Text('Cập nhật thông tin cá nhân'),
                        subtitle: const Text('Đổi họ tên, cập nhật ảnh đại diện'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showEditProfileDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_reset_outlined, color: Colors.orange),
                        title: const Text('Đổi mật khẩu'),
                        subtitle: const Text('Thay đổi mật khẩu tài khoản'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showChangePasswordDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text('Đăng xuất'),
                        subtitle: const Text('Thoát khỏi phiên làm việc hiện tại'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
