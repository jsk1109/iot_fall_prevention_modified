import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_user_management_screen.dart'; // 사용자 관리 상세 화면 import

class AdminScreen extends StatelessWidget {
  final String adminId;
  const AdminScreen({super.key, required this.adminId});

  // 대시보드 카드 UI를 만드는 공용 위젯
  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              // AuthProvider의 로그아웃 함수를 호출하고 로그인 화면으로 이동합니다.
              context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // 한 줄에 2개의 카드 표시
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // 사용자 관리 카드
            _buildDashboardCard(
              context: context,
              icon: Icons.people_alt,
              title: '사용자 관리',
              onTap: () {
                // 사용자 관리 상세 화면으로 이동합니다.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminUserManagementScreen(adminId: adminId),
                  ),
                );
              },
            ),
            // 통계 카드 (준비 중)
            _buildDashboardCard(
              context: context,
              icon: Icons.bar_chart,
              title: '통계 (준비 중)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('아직 준비 중인 기능입니다.')),
                );
              },
            ),
            // 환자 관리 카드 (준비 중)
            _buildDashboardCard(
              context: context,
              icon: Icons.medical_services_outlined,
              title: '환자 관리 (준비 중)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('아직 준비 중인 기능입니다.')),
                );
              },
            ),
            // 센서 관리 카드 (준비 중)
            _buildDashboardCard(
              context: context,
              icon: Icons.sensors,
              title: '센서 관리 (준비 중)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('아직 준비 중인 기능입니다.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
