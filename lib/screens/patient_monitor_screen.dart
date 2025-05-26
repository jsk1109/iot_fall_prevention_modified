import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/sensor_data_card.dart';
import '../services/dynamodb_service.dart';

// 환자 모니터 화면
class PatientMonitorScreen extends StatefulWidget {
  final String patientId;

  const PatientMonitorScreen({super.key, required this.patientId});

  @override
  State<PatientMonitorScreen> createState() => _PatientMonitorScreenState();
}

class _PatientMonitorScreenState extends State<PatientMonitorScreen> {
  final DynamoDBService _dynamoDBService = DynamoDBService();
  List<Map<String, dynamic>> _sensorData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSensorData();
  }

  // 센서 데이터 로드
  Future<void> _loadSensorData() async {
    setState(() => _isLoading = true);
    try {
      // DynamoDBService의 임시 로컬 버전에서는 getPatientData를 사용합니다.
      final data = await _dynamoDBService.getPatientData(widget.patientId);
      setState(() {
        _sensorData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('센서 데이터를 불러오는데 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = context
        .read<PatientProvider>()
        .patients
        .firstWhere((p) => p.id == widget.patientId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${patient.name}님 모니터링'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: FCM을 사용하여 알림을 발송할 예정입니다.
              // 예시 코드:
              // fcmService.sendNotification('알림 제목', '알림 내용');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('알림이 발송되었습니다. (기능 구현 예정)'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSensorData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '낙상 위험도: ${patient.isFallRisk ? "높음" : "정상"}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: patient.isFallRisk ? Colors.red : Colors.green,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: 환자 호출 알람 발송
                          // AWS와 FCM을 사용하여 호출 알람을 발송할 예정입니다.
                          // 예시 코드:
                          // final response = await awsService.sendAlert(patientId);
                          // fcmService.sendNotification('환자 호출 알람', '환자가 호출 버튼을 눌렀습니다.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('호출 알람이 발송되었습니다. (기능 구현 예정)'),
                            ),
                          );
                        },
                        child: const Text('호출'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sensorData.length,
                    itemBuilder: (context, index) {
                      final data = _sensorData[index];
                      return SensorDataCard(
                        temperature: data['temperature'],
                        humidity: data['humidity'],
                        pressure: data['pressure'],
                        timestamp: data['timestamp'],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
