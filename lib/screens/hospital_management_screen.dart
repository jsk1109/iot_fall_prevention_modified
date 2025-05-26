import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HospitalManagementScreen extends StatefulWidget {
  const HospitalManagementScreen({super.key});

  @override
  State<HospitalManagementScreen> createState() =>
      _HospitalManagementScreenState();
}

class _HospitalManagementScreenState extends State<HospitalManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // 슈퍼 관리자 권한 체크
    if (authProvider.userRole != UserRole.superAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('접근 제한'),
        ),
        body: const Center(
          child: Text('슈퍼 관리자만 접근할 수 있는 페이지입니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('병원 목록'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 통계 카드
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Flexible(
                    child: _buildStatCard(
                      '전체 병원',
                      '2',
                      Icons.business,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: _buildStatCard(
                      '전체 환자',
                      '15',
                      Icons.people,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: _buildStatCard(
                      '고위험 환자',
                      '3',
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            // 병원 목록
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
                    // TODO: 병원 정보 수정 다이얼로그 표시
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('삭제'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('병원 삭제'),
                        content: Text('$name을(를) 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: AWS DynamoDB에서 병원 정보 삭제
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$name이(가) 삭제되었습니다.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            child: const Text(
                              '삭제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
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
