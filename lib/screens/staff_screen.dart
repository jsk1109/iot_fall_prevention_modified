import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/patient_model.dart';
import '../models/sensor_data.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

// 환자 정보와 마지막 이벤트 정보를 묶는 데이터 클래스
class PatientEventData {
  final Patient patient;
  final SensorData? lastEvent;

  PatientEventData({required this.patient, this.lastEvent});
}

class StaffScreen extends StatefulWidget {
  final String staffId;
  const StaffScreen({super.key, required this.staffId});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late Future<List<PatientEventData>> _dashboardDataFuture;
  Timer? _timer;
  DateTime? _lastUpdated;

  // [추가] 알림 기능을 위한 상태 변수
  // Key: 환자 ID, Value: 마지막으로 알려진 이벤트의 고유 ID
  Map<String, int> _lastKnownEventIds = {};
  // 처음 로드할 때는 알림을 띄우지 않기 위한 플래그
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<PatientEventData>> _fetchDashboardData() async {
    final List<Patient> patients =
        await ApiService.getAllPatients(widget.staffId);
    final List<PatientEventData> combinedData = [];

    for (var patient in patients) {
      SensorData? mostRecentEvent;
      try {
        mostRecentEvent = await ApiService.getMostRecentEventForPatient(
            patient.roomId, patient.bedId);
      } catch (e) {
        print("환자(${patient.patientId})의 이벤트 없음: $e");
      }

      combinedData
          .add(PatientEventData(patient: patient, lastEvent: mostRecentEvent));
    }
    return combinedData;
  }

  // [수정] 데이터 로드 후 알림 체크 로직 추가
  Future<void> _loadData() async {
    // FutureBuilder가 화면을 계속 그리도록 Future를 먼저 설정
    final future = _fetchDashboardData();
    if (mounted) {
      setState(() {
        _dashboardDataFuture = future;
      });
    }

    try {
      // API 호출이 완료될 때까지 기다림
      final newDashboardData = await future;
      if (!mounted) return;

      // [핵심] 새로운 데이터와 이전 상태를 비교하여 알림을 발생시킴
      _checkForNewEvents(newDashboardData);

      // 마지막 업데이트 시간 갱신
      setState(() {
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      print("데이터 로딩 중 에러: $e");
    }
  }

  // [추가] 새로운 이벤트를 확인하고 알림을 띄우는 함수
  void _checkForNewEvents(List<PatientEventData> newDashboardData) {
    // 현재 API에서 가져온 최신 이벤트 목록을 Map 형태로 변환
    final newEventMap = <String, int>{};
    for (var data in newDashboardData) {
      if (data.lastEvent != null) {
        newEventMap[data.patient.patientId] = data.lastEvent!.id;
      }
    }

    // 앱이 처음 로드될 때의 처리
    if (_isFirstLoad) {
      _lastKnownEventIds = newEventMap; // 현재 상태를 초기 상태로 저장
      _isFirstLoad = false;
      return; // 첫 로드 시에는 알림을 보내지 않음
    }

    // 새로운 이벤트 확인
    for (var patientId in newEventMap.keys) {
      // 이전 상태에 없던 새로운 이벤트가 발생했거나, 기존 이벤트가 다른 ID의 새 이벤트로 변경되었을 때
      if (!_lastKnownEventIds.containsKey(patientId) ||
          _lastKnownEventIds[patientId] != newEventMap[patientId]) {
        final newData = newDashboardData
            .firstWhere((d) => d.patient.patientId == patientId);
        _showNewEventNotification(newData.patient, newData.lastEvent!);
      }
    }

    // 다음 비교를 위해 현재 상태를 최신 상태로 업데이트
    _lastKnownEventIds = newEventMap;
  }

  // [추가] SnackBar 알림을 표시하는 위젯
  void _showNewEventNotification(Patient patient, SensorData event) {
    if (!mounted) return; // 위젯이 화면에 없을 때는 실행하지 않음

    // 이전 SnackBar가 있다면 지우고 새 것을 표시
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚨 ${patient.patientName} (${patient.roomId}호/${patient.bedId}침대): ${event.value}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            event.type == 'fall' ? Colors.red.shade800 : Colors.blue.shade800,
        duration: const Duration(seconds: 5), // 5초간 표시
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(authProvider.nursingHomeName ?? '통합 모니터링'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
              onPressed: _loadData),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _lastUpdated != null
                  ? '마지막 업데이트: ${DateFormat('HH:mm:ss').format(_lastUpdated!)}'
                  : '데이터 로딩 중...',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: FutureBuilder<List<PatientEventData>>(
          future: _dashboardDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('데이터를 불러오는 중 에러가 발생했습니다: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('등록된 환자가 없습니다.'));
            }

            final dashboardList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: dashboardList.length,
              itemBuilder: (context, index) {
                final data = dashboardList[index];
                final patient = data.patient;
                final event = data.lastEvent;
                final hasEvent = event != null;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: hasEvent
                              ? (event.type == 'fall'
                                  ? Colors.red.shade400
                                  : Colors.blue.shade400)
                              : Colors.grey.shade300,
                          width: 1.5)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${patient.patientName} (${patient.patientId})',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text('${patient.roomId}호 / ${patient.bedId}침대',
                                style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                        const Divider(height: 24),
                        if (hasEvent)
                          _buildEventTile(event)
                        else
                          const Text('최근 이벤트 없음',
                              style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventTile(SensorData event) {
    final isFallEvent = event.type == 'fall';
    final icon =
        isFallEvent ? Icons.warning_amber_rounded : Icons.notifications_active;
    final color = isFallEvent ? Colors.red.shade700 : Colors.blue.shade700;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            event.value,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: color, fontSize: 16),
          ),
        ),
        Text(DateFormat('MM/dd HH:mm').format(event.timestamp)),
      ],
    );
  }
}
