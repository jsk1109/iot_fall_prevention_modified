import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import 'hospital_management_screen.dart';
import 'patient_management_screen.dart';
import 'permission_management_screen.dart';
import 'hospital_registration_screen.dart';
import 'patient_registration_screen.dart';

/// 관리자/슈퍼 어드민 메인 대시보드 화면
/// - 슈퍼 어드민은 로그인 후 이 화면에서 병원 목록, 새 병원 등록, 전체 통계, 권한 관리 등 시스템 전체 기능을 한눈에 볼 수 있음
/// - 병원 선택 시 해당 병원 대시보드로 이동
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();

    // 권한 체크: 일반 직원은 접근 불가
    if (authProvider.userRole == UserRole.staff) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('접근 제한'),
        ),
        body: const Center(
          child: Text('관리자 권한이 필요합니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(authProvider.userRole == UserRole.superAdmin
            ? '시스템 관리(슈퍼 어드민 대시보드)'
            : '${authProvider.hospitalName} 관리'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 시스템 통계(슈퍼 어드민/병원 관리자) ---
            if (authProvider.userRole != UserRole.superAdmin) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${authProvider.hospitalName} 통계',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        '전체 환자',
                        patientProvider.patients.length.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatRow(
                        '고위험 환자',
                        patientProvider.patients
                            .where((p) => p.isHighRisk)
                            .length
                            .toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                      _buildStatRow(
                        '위험 상태 환자',
                        patientProvider.patients
                            .where((p) => p.status == '위험')
                            .length
                            .toString(),
                        Icons.error,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- 슈퍼 어드민 전용 시스템 관리 메뉴 ---
            if (authProvider.userRole == UserRole.superAdmin) ...[
              const Text(
                '시스템 관리',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('병원 목록 관리'),
                  subtitle: const Text('등록된 병원 전체 보기/수정/삭제'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HospitalManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_business),
                  title: const Text('새 병원 등록'),
                  subtitle: const Text('새로운 병원 추가'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const HospitalRegistrationScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- 환자 관리 메뉴 ---
            const Text(
              '환자 관리',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('새 환자 등록'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientRegistrationScreen(),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('환자 목록 관리'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientManagementScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // --- 권한 관리 메뉴 ---
            if (authProvider.userRole == UserRole.hospitalAdmin ||
                authProvider.userRole == UserRole.superAdmin)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('권한 관리'),
                  subtitle: const Text('직원/관리자 권한 설정'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PermissionManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 통계(대시보드) 카드의 한 줄을 그리는 위젯
  /// - label: 통계명, value: 값, icon: 아이콘, color: 아이콘 색상
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
