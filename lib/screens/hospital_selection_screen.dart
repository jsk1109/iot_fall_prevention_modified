import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'hospital_management_screen.dart';
import 'hospital_registration_screen.dart';

/// 슈퍼 관리자를 위한 병원 선택 화면
///
/// 이 화면에서는 다음과 같은 기능을 제공합니다:
/// 1. 현재 선택된 병원 정보 표시
/// 2. 병원 간 전환 기능
/// 3. 새로운 병원 등록
/// 4. 전체 병원 목록 조회
class HospitalSelectionScreen extends StatelessWidget {
  const HospitalSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.userRole;

    // 슈퍼 관리자만 접근 가능
    if (userRole != UserRole.superAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('접근 제한'),
        ),
        body: const Center(
          child: Text('이 페이지는 슈퍼 관리자만 접근할 수 있습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('병원 선택'),
        actions: [
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // 현재 선택된 병원 표시
            if (authProvider.hospitalName != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.business, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '현재 선택된 병원',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authProvider.hospitalName!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('병원 전환'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _showHospitalSelectionDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            // 병원 목록 제목과 새 병원 등록 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.list,
                            color: Colors.blue.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '등록된 병원 목록',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('새 병원 등록'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HospitalRegistrationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // 병원 목록
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHospitalCard(
                    context,
                    '서울대병원',
                    '서울특별시 종로구 대학로 101',
                    '02-2072-2114',
                  ),
                  _buildHospitalCard(
                    context,
                    '연세대병원',
                    '서울특별시 서대문구 연세로 50-1',
                    '02-2228-0114',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 병원 선택 다이얼로그를 표시합니다.
  void _showHospitalSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('병원 선택'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildHospitalListTile(
                context,
                '서울대병원',
                '서울특별시 종로구 대학로 101',
                '02-2072-2114',
              ),
              _buildHospitalListTile(
                context,
                '연세대병원',
                '서울특별시 서대문구 연세로 50-1',
                '02-2228-0114',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 병원 목록의 각 항목을 표시하는 ListTile을 생성합니다.
  Widget _buildHospitalListTile(
    BuildContext context,
    String name,
    String address,
    String phone,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.business, color: Colors.blue.shade700),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(address),
          Text(phone),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        final authProvider = context.read<AuthProvider>();
        authProvider.setHospital('H001', name); // TODO: 실제 병원 ID 사용
        Navigator.pushReplacementNamed(context, '/home');
      },
    );
  }

  /// 병원 정보를 표시하는 카드를 생성합니다.
  Widget _buildHospitalCard(
    BuildContext context,
    String name,
    String address,
    String phone,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.business, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(child: Text(address)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(phone),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('수정'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HospitalManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('선택'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final authProvider = context.read<AuthProvider>();
                    authProvider.setHospital('H001', name); // TODO: 실제 병원 ID 사용
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
