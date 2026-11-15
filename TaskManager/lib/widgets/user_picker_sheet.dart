import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/collab_service.dart';

String userInitial(TaskUser u) =>
    u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?';

// Mở bảng tìm và chọn nhiều người dùng. Trả về danh sách đã chọn (hoặc null nếu hủy).
Future<List<TaskUser>?> showUserPicker(
  BuildContext context, {
  required String title,
  Set<String> excludeIds = const {},
}) {
  return showModalBottomSheet<List<TaskUser>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _UserPickerSheet(title: title, excludeIds: excludeIds),
  );
}

class _UserPickerSheet extends StatefulWidget {
  final String title;
  final Set<String> excludeIds;

  const _UserPickerSheet({required this.title, required this.excludeIds});

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final _controller = TextEditingController();
  final _service = CollabService();
  Timer? _debounce;

  List<TaskUser> _results = [];
  final Map<String, TaskUser> _selected = {};
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _service.searchUsers(q);
      if (!mounted) return;
      setState(() {
        _results = users.where((u) => !widget.excludeIds.contains(u.id)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          _controller.text.trim().isEmpty
              ? 'Nhập tên hoặc email để tìm người dùng'
              : 'Không tìm thấy người dùng nào',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final u = _results[index];
        return CheckboxListTile(
          value: _selected.containsKey(u.id),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selected[u.id] = u;
              } else {
                _selected.remove(u.id);
              }
            });
          },
          title: Text(u.fullName),
          subtitle: Text(u.email),
          secondary: CircleAvatar(child: Text(userInitial(u))),
          controlAffinity: ListTileControlAffinity.trailing,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 480,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm theo tên hoặc email...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildList()),
              FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selected.values.toList()),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                child: Text('Chọn (${_selected.length})'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
