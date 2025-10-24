import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/patient_model.dart';
import '../models/sensor_data.dart'; // SensorData 모델 import 확인
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import './bed_monitor_screen.dart'; // 새로 만든 침대 모니터링 화면 import

// 환자 정보와 마지막 이벤트 정보를 묶는 데이터 클래스
class PatientEventData {
  final Patient patient;
  final SensorData? lastEvent; // 이벤트 없을 수 있음 (nullable)

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

  // 알림 기능 관련 변수
  Map<String, int> _lastKnownEventIds = {};
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

  // 서버로부터 환자 목록과 각 환자의 마지막 이벤트 가져오기
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

  // 데이터 로드 및 알림 체크
  Future<void> _loadData() async {
    final future = _fetchDashboardData();
    if (mounted) {
      setState(() {
        _dashboardDataFuture = future;
      });
    }

    try {
      final newDashboardData = await future;
      if (!mounted) return;
      _checkForNewEvents(newDashboardData); // 알림 체크 함수 호출
      setState(() {
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      print("데이터 로딩 중 에러: $e");
    }
  }

  // 새로운 이벤트 확인 및 알림 표시
  void _checkForNewEvents(List<PatientEventData> newDashboardData) {
    final newEventMap = <String, int>{};
    for (var data in newDashboardData) {
      if (data.lastEvent != null) {
        newEventMap[data.patient.patientId] = data.lastEvent!.id;
      }
    }

    if (_isFirstLoad) {
      _lastKnownEventIds = newEventMap;
      _isFirstLoad = false;
      return;
    }

    for (var patientId in newEventMap.keys) {
      if (!_lastKnownEventIds.containsKey(patientId) ||
          _lastKnownEventIds[patientId] != newEventMap[patientId]) {
        final newData = newDashboardData
            .firstWhere((d) => d.patient.patientId == patientId);
        // lastEvent가 null이 아닐 때만 알림 표시
        if (newData.lastEvent != null) {
          _showNewEventNotification(newData.patient, newData.lastEvent!);
        }
      }
    }
    _lastKnownEventIds = newEventMap;
  }

  // SnackBar 알림 표시
  void _showNewEventNotification(Patient patient, SensorData event) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚨 ${patient.patientName} (${patient.roomId}호/${patient.bedId}침대): ${event.value}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            event.type == 'fall' ? Colors.red.shade800 : Colors.blue.shade800,
        duration: const Duration(seconds: 5),
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
                  ? '마지막 업데이트: ${DateFormat('HH:mm:ss').format(_lastUpdated!.toLocal())}' // 현지 시간으로 표시
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
            // --- 여기가 수정된 부분 ---
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: dashboardList.length,
              itemBuilder: (context, index) {
                final data = dashboardList[index];
                final patient = data.patient;
                final event = data.lastEvent;
                final hasEvent = event != null;

                // [수정] Card 위젯을 GestureDetector로 감싸서 탭 기능 추가
                return GestureDetector(
                  onTap: () {
                    // 탭하면 BedMonitorScreen으로 이동하면서 현재 Patient 객체 전달
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BedMonitorScreen(patient: patient),
                      ),
                    );
                  },
                  child: Card(
                    // 카드 UI 시작
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3, // 그림자
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                        // 이벤트 상태에 따라 테두리 색상 변경
                        side: BorderSide(
                            color: hasEvent
                                ? (event!.type == 'fall'
                                    ? Colors.red.shade400
                                    : Colors.blue.shade400)
                                : Colors.grey.shade300,
                            width: 1.5)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 환자 정보 행
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${patient.patientName} (${patient.patientId})',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              // 방/침대 정보
                              Text('${patient.roomId}호 / ${patient.bedId}침대',
                                  style:
                                      TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                          const Divider(height: 24), // 구분선
                          // 이벤트 정보 표시 (있을 경우)
                          if (hasEvent)
                            _buildEventTile(
                                event!) // 이벤트 타일 위젯 호출 (Null 아님을 보장)
                          else
                            const Text('최근 이벤트 없음',
                                style:
                                    TextStyle(color: Colors.grey)), // 이벤트 없을 때
                        ],
                      ),
                    ),
                  ), // 카드 UI 끝
                ); // GestureDetector 끝
              },
            );
            // --- 수정 끝 ---
          },
        ),
      ),
    );
  }

  // 이벤트 정보를 표시하는 위젯 (이전과 동일)
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
        // 이벤트 발생 시간 (현지 시간으로)
        Text(DateFormat('MM/dd HH:mm').format(event.timestamp.toLocal())),
      ],
    );
  }
} // _StaffScreenState 클래스 끝

