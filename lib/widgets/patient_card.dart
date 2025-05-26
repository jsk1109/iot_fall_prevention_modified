import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/auth_provider.dart';
import '../models/patient.dart';

// 환자 정보를 표시하는 카드 위젯
class PatientCard extends StatelessWidget {
  final Patient patient;

  const PatientCard({
    super.key,
    required this.patient,
  });

  // 상태에 따른 색상 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case '정상':
        return Colors.green;
      case '주의':
        return Colors.orange;
      case '위험':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showStatusChangeDialog(BuildContext context) {
    final patientProvider = context.read<PatientProvider>();
    final authProvider = context.read<AuthProvider>();
    final canEdit = authProvider.userRole == UserRole.doctor ||
        authProvider.userRole == UserRole.nurse ||
        authProvider.userRole == UserRole.hospitalAdmin;

    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('상태를 변경할 권한이 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${patient.name}님의 상태 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(
              context,
              '정상',
              Colors.green,
              patient.status == '정상',
              () {
                patientProvider.updatePatientStatus(patient.id, '정상');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _buildStatusOption(
              context,
              '주의',
              Colors.orange,
              patient.status == '주의',
              () {
                patientProvider.updatePatientStatus(patient.id, '주의');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _buildStatusOption(
              context,
              '위험',
              Colors.red,
              patient.status == '위험',
              () {
                patientProvider.updatePatientStatus(patient.id, '위험');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('고위험 환자'),
              value: patient.isHighRisk,
              onChanged: (value) {
                // TODO: 고위험 환자 상태 업데이트 기능 구현
                Navigator.pop(context);
              },
              activeColor: Colors.red,
            ),
          ],
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

  Widget _buildStatusOption(
    BuildContext context,
    String status,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              status,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canEdit = authProvider.userRole == UserRole.doctor ||
        authProvider.userRole == UserRole.nurse ||
        authProvider.userRole == UserRole.hospitalAdmin;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showStatusChangeDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(patient.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(patient.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(patient.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          patient.status,
                          style: TextStyle(
                            color: _getStatusColor(patient.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (canEdit) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: _getStatusColor(patient.status),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${patient.age}세 (${patient.gender})',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.door_front_door,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${patient.room}호',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.medical_services,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    patient.diagnosis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.warning, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '위험도: ${patient.riskLevel}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
