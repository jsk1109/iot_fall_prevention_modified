import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// 1. 필요한 모델을 정확히 import합니다.
import '../models/patient_model.dart';
// 'sensor_data.dart'는 삭제되었으므로, 'ultrasonic_data.dart'를 import합니다.
import '../models/ultrasonic_data.dart' as model;
import '../providers/auth_provider.dart' as auth_p;
import '../services/api_service.dart';
import './bed_monitor_screen.dart';

// 2. 데이터 클래스: Patient와 최신 UltrasonicU4Response를 묶습니다.
class PatientEventData {
  final Patient patient;
  // SensorData 대신 model.UltrasonicU4Response를 사용합니다.
  final model.UltrasonicU4Response? lastEvent;

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

  Map<String, int> _lastKnownEventIds = {};
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 10초 타이머 유지
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 3. 서버로부터 환자 목록과 각 환자의 마지막 'ultrasonic_u4' 로그를 가져옵니다.
  Future<List<PatientEventData>> _fetchDashboardData() async {
    final List<Patient> patients = await ApiService.getAllPatients();
    final List<PatientEventData> combinedData = [];

    for (var patient in patients) {
      model.UltrasonicU4Response? mostRecentEvent;
      try {
        final List<model.UltrasonicU4Response> history =
            await ApiService.getUltrasonicHistory(patient.bedId, limit: 1);

        if (history.isNotEmpty) {
          mostRecentEvent = history.last;
        }
      } catch (e) {
        print("환자(${patient.patientId})의 이벤트 없음: $e");
      }

      combinedData
          .add(PatientEventData(patient: patient, lastEvent: mostRecentEvent));
    }
    return combinedData;
  }

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
      _checkForNewEvents(newDashboardData);
      setState(() {
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      print("데이터 로딩 중 에러: $e");
    }
  }

  // 4. 새로운 이벤트 확인 (UltrasonicU4Response의 data_id 기준)
  void _checkForNewEvents(List<PatientEventData> newDashboardData) {
    final newEventMap = <String, int>{};
    for (var data in newDashboardData) {
      if (data.lastEvent != null) {
        newEventMap[data.patient.patientId] = data.lastEvent!.dataId;
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

        if (newData.lastEvent != null) {
          // 5. fall_event 또는 call_button이 true일 때만 알림
          if (newData.lastEvent!.fallEvent || newData.lastEvent!.callButton) {
            _showNewEventNotification(newData.patient, newData.lastEvent!);
          }
        }
      }
    }
    _lastKnownEventIds = newEventMap;
  }

  // 6. 알림 표시 (UltrasonicU4Response 사용)
  void _showNewEventNotification(
      Patient patient, model.UltrasonicU4Response event) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final String message;
    final Color color;
    if (event.fallEvent) {
      message = "낙상 감지";
      color = Colors.red.shade800;
    } else if (event.callButton) {
      message = "환자 호출";
      color = Colors.blue.shade800;
    } else {
      return; // 둘 다 아니면 알림 없음
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚨 ${patient.patientName} (${patient.roomId}호/${patient.bedId}침대): $message',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth_p.AuthProvider>();
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
              context.read<auth_p.AuthProvider>().logout();
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
                  ? '마지막 업데이트: ${DateFormat('HH:mm:ss').format(_lastUpdated!.toLocal())}'
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
                // 7. 이벤트 유무 판단 (fall_event 또는 call_button)
                final bool hasEvent =
                    event != null && (event.fallEvent || event.callButton);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BedMonitorScreen(patient: patient),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: hasEvent
                                ? (event!.fallEvent
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text('${patient.roomId}호 / ${patient.bedId}침대',
                                  style:
                                      TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                          const Divider(height: 24),
                          // 8. 이벤트 정보 표시 (UltrasonicU4Response 사용)
                          if (hasEvent)
                            _buildEventTile(event!) // 이벤트 타일 위젯 호출
                          else
                            const Text('최근 이벤트 없음',
                                style: TextStyle(color: Colors.grey)),
                        ],
                      ),
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

  // 9. 이벤트 타일 위젯 (UltrasonicU4Response 사용)
  Widget _buildEventTile(model.UltrasonicU4Response event) {
    final bool isFallEvent = event.fallEvent;
    final icon =
        isFallEvent ? Icons.warning_amber_rounded : Icons.notifications_active;
    final color = isFallEvent ? Colors.red.shade700 : Colors.blue.shade700;
    final String value = isFallEvent ? "낙상 감지" : "환자 호출";

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: color, fontSize: 16),
          ),
        ),
        Text(DateFormat('MM/dd HH:mm').format(event.timestamp.toLocal())),
      ],
    );
  }
}
