import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import './admin_user_management_screen.dart'; // 사용자 관리 화면 import
import './staff_screen.dart'; // 직원(모니터링) 화면 import

class AdminScreen extends StatelessWidget {
  final String adminId; // 관리자 ID를 받음
  const AdminScreen({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>(); // 사용자 이름 표시용

    return Scaffold(
      appBar: AppBar(
        title: Text('${authProvider.nursingHomeName ?? '관리자'} 메뉴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 버튼들을 중앙에 배치
          crossAxisAlignment: CrossAxisAlignment.stretch, // 버튼 너비 최대로
          children: [
            // 1. 사용자 역할 관리 버튼
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
                    builder: (context) =>
                        AdminUserManagementScreen(adminId: adminId),
                  ),
                );
              },
            ),
            const SizedBox(height: 20), // 버튼 사이 간격

            // 2. 실시간 모니터링 화면 이동 버튼
            ElevatedButton.icon(
              icon: const Icon(Icons.monitor_heart),
              label: const Text('실시간 모니터링'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                // 관리자 ID를 staffId로 넘겨서 StaffScreen으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffScreen(staffId: adminId),
                  ),
                );
              },
            ),
            // --- 향후 다른 관리 기능 버튼을 여기에 추가 ---
          ],
        ),
      ),
    );
  }
}
