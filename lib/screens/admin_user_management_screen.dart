import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final String adminId;
  const AdminUserManagementScreen({super.key, required this.adminId});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _reloadUsers();
  }

  void _reloadUsers() {
    setState(() {
      _usersFuture = ApiService.getAllUsers(widget.adminId);
    });
  }

  void _changeRole(User user, String newRole) async {
    bool success = await ApiService.updateUserRole(
        user.nursinghomeId, newRole, widget.adminId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${user.nursinghomeName}님의 역할이 변경되었습니다.'),
        backgroundColor: Colors.green,
      ));
      _reloadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('역할 변경에 실패했습니다.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 역할 관리'),
      ),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('등록된 사용자가 없습니다.'));
          }

          final users = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reloadUsers(),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(user.role == 'admin'
                          ? Icons.admin_panel_settings
                          : Icons.person),
                    ),
                    title:
                        Text('${user.nursinghomeName} (${user.nursinghomeId})'),
                    subtitle: Text(user.email),
                    trailing: DropdownButton<String>(
                      value: user.role,
                      items: ['staff', 'admin'].map((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value.toUpperCase()));
                      }).toList(),
                      onChanged: (String? newRole) {
                        // 자기 자신의 역할은 변경할 수 없도록 방지
                        if (user.nursinghomeId == widget.adminId) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('자기 자신의 역할은 변경할 수 없습니다.'),
                          ));
                          return;
                        }
                        if (newRole != null && newRole != user.role) {
                          _changeRole(user, newRole);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
