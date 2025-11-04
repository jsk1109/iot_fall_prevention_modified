import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:iot_fall_prevention/providers/auth_provider.dart' as auth_p;
import 'package:iot_fall_prevention/screens/admin_user_management_screen.dart';
import 'package:iot_fall_prevention/screens/staff_screen.dart';

class AdminScreen extends StatelessWidget {
  final String adminId;
  const AdminScreen({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    // 3. 접두사를 사용하여 Provider 참조
    final authProvider = context.watch<auth_p.AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${authProvider.nursingHomeName ?? '관리자'} 메뉴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              // 4. 접두사를 사용하여 Provider 참조
              context.read<auth_p.AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.manage_accounts),
              label: const Text('사용자 역할 관리'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // 5. [핵심 수정] 명시적 생성자 호출
                    builder: (context) =>
                        AdminUserManagementScreen(adminId: adminId),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.monitor_heart),
              label: const Text('실시간 모니터링'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffScreen(staffId: adminId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
