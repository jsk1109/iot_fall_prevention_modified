import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/patient_card.dart';
import 'admin_screen.dart';
import 'hospital_selection_screen.dart';

// 홈 화면
// 사용자가 로그인 후 볼 수 있는 메인 화면으로, 환자 목록을 표시합니다.
// 사용자는 환자 목록을 보고, 환자 정보를 확인하거나 새로운 환자를 추가할 수 있습니다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthProvider와 PatientProvider를 통해 사용자 인증 정보와 환자 정보를 가져옵니다.
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();
    final userRole = authProvider.userRole;
    final hospitalName = authProvider.hospitalName;
    final isAdmin =
        userRole == UserRole.hospitalAdmin || userRole == UserRole.superAdmin;

    // 슈퍼 어드민이 병원을 선택하지 않은 경우 병원 선택 화면으로 이동
    if (userRole == UserRole.superAdmin &&
        (hospitalName == null || hospitalName.isEmpty)) {
      // 병원 선택이 안 된 경우 병원 선택 화면으로 이동
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HospitalSelectionScreen(),
          ),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(hospitalName ?? '홈'),
        actions: [
          // 슈퍼 어드민은 병원 전환 버튼만 제공
          if (userRole == UserRole.superAdmin)
            IconButton(
              icon: const Icon(Icons.business),
              tooltip: '병원 전환',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HospitalSelectionScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '알림 설정',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 설정 기능 준비 중입니다.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: '관리자 메뉴',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환영 메시지와 역할 표시
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${authProvider.currentUser ?? '사용자'}님 환영합니다',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRoleText(userRole),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 병원별 대시보드(슈퍼 어드민도 병원 선택 후에는 해당 병원 정보만 표시)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${hospitalName ?? '병원'} 현황',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Flexible(
                        child: _buildDashboardCard(
                          context,
                          '전체 환자',
                          patientProvider.patients.length.toString(),
                          Icons.people,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: _buildDashboardCard(
                          context,
                          '고위험 환자',
                          patientProvider.patients
                              .where((p) => p.isHighRisk)
                              .length
                              .toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: _buildDashboardCard(
                          context,
                          '위험 상태 환자',
                          patientProvider.patients
                              .where((p) => p.status == '위험')
                              .length
                              .toString(),
                          Icons.error,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 환자 목록
            Column(
              children: patientProvider.patients
                  .map((patient) => PatientCard(patient: patient))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 대시보드(통계) 카드 위젯
  /// - 각 통계(전체 환자, 고위험 환자, 위험 상태 환자 등)를 카드 형태로 표시
  /// - 카드 크기는 Flexible로 제한, 텍스트는 오버플로우 방지
  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 사용자 역할을 한글로 반환하는 메서드
  String _getRoleText(UserRole? role) {
    switch (role) {
      case UserRole.superAdmin:
        return '슈퍼 관리자';
      case UserRole.hospitalAdmin:
        return '병원 관리자';
      case UserRole.doctor:
        return '의사';
      case UserRole.nurse:
        return '간호사';
      case UserRole.staff:
        return '일반 직원';
      default:
        return '미지정';
    }
  }
}
