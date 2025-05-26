import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../models/patient.dart';

class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 목록 관리'),
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
            // 통계 카드
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${authProvider.hospitalName} 환자 현황',
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
                      ),
                      _buildStatRow(
                        '고위험 환자',
                        patientProvider.patients
                            .where((p) => p.isHighRisk)
                            .length
                            .toString(),
                        Icons.warning,
                        color: Colors.red,
                      ),
                      _buildStatRow(
                        '위험 상태 환자',
                        patientProvider.patients
                            .where((p) => p.status == '위험')
                            .length
                            .toString(),
                        Icons.error,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 환자 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: patientProvider.patients.length,
                itemBuilder: (context, index) {
                  final patient = patientProvider.patients[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(patient.status),
                        child: Icon(
                          _getStatusIcon(patient.status),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        patient.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('나이: ${patient.age}세'),
                          Text('성별: ${patient.gender}'),
                          Text('병실: ${patient.room}'),
                          Text('진단명: ${patient.diagnosis}'),
                          Text('위험도: ${patient.riskLevel}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: 환자 정보 수정 기능 구현
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // TODO: 환자 삭제 기능 구현
                            },
                          ),
                        ],
                      ),
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

  Widget _buildStatRow(String label, String value, IconData icon,
      {Color color = Colors.blue}) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case '위험':
        return Colors.red;
      case '주의':
        return Colors.orange;
      case '정상':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case '위험':
        return Icons.error;
      case '주의':
        return Icons.warning;
      case '정상':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }
}
