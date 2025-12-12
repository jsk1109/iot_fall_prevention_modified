import 'package:flutter/material.dart';
import 'dart:async';
import 'package:iot_fall_prevention/services/api_service.dart';
import 'package:iot_fall_prevention/models/sensor_data_model.dart';
import 'package:iot_fall_prevention/models/patient_model.dart';
import 'package:iot_fall_prevention/screens/bed_monitor_screen.dart';

class StaffScreen extends StatefulWidget {
  final String staffId;
  const StaffScreen({super.key, required this.staffId});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<Patient> _allPatients = [];
  List<SensorDataModel> _rawLogs = [];
  List<Map<String, dynamic>> _bedStatusList = [];

  // 알림이 활성화된 침대 목록 (낙상 1, 2 포함)
  final Set<String> _activeFallAlerts = {};
  final Set<String> _activeCallAlerts = {};

  // 확인 처리된 로그 ID 목록
  final Set<int> _dismissedLogIds = {};

  Timer? _timer;
  bool _isLoading = true;

  String _lastUpdateTime = "연결 중...";
  final String _currentNursingHomeId = "NH-001";

  @override
  void initState() {
    super.initState();
    _initData();
    _timer =
        Timer.periodic(const Duration(seconds: 3), (timer) => _fetchLogsOnly());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    if (!mounted) return;
    try {
      final patients = await ApiService.getAllPatients();
      final logs = await ApiService.getStaffLogs(_currentNursingHomeId);

      if (mounted) {
        setState(() {
          _allPatients = patients;
          _rawLogs = logs;
          _processBedData();
          _updateTime();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error init data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLogsOnly() async {
    if (!mounted) return;
    try {
      final logs = await ApiService.getStaffLogs(_currentNursingHomeId);
      if (mounted) {
        setState(() {
          _rawLogs = logs;
          _processBedData();
          _updateTime();
        });
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    _lastUpdateTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  void _processBedData() {
    final Map<String, Map<String, dynamic>> bedMap = {};

    // 1. 기본 침대 정보 세팅
    for (var patient in _allPatients) {
      final key = '${patient.roomId}-${patient.bedId}';
      bedMap[key] = {
        'key': key,
        'patientName': patient.patientName,
        'roomId': patient.roomId,
        'bedId': patient.bedId,
        'currentLog': null,
        'lastFallTime': null,
      };
    }

    // 2. 로그 데이터 매핑
    for (var log in _rawLogs) {
      final key = '${log.roomId}-${log.bedId}';

      if (bedMap.containsKey(key)) {
        // 최신 로그 저장
        if (bedMap[key]!['currentLog'] == null) {
          bedMap[key]!['currentLog'] = log;
        }

        // 마지막 낙상 시간 (Event 2만 기록)
        if (log.fallEvent == 2 && bedMap[key]!['lastFallTime'] == null) {
          bedMap[key]!['lastFallTime'] = log.timestamp;
        }
      }
    }

    // 3. 알림 트리거 로직 (최신 로그 기준)
    bedMap.forEach((key, data) {
      final SensorDataModel? currentLog = data['currentLog'];

      if (currentLog != null) {
        // 1(주의) 또는 2(낙상) 상태이고 && 아직 확인 안 함 -> 알림 목록 추가
        bool isFallOrWarning =
            (currentLog.fallEvent == 1 || currentLog.fallEvent == 2);

        if (isFallOrWarning && !_dismissedLogIds.contains(currentLog.id)) {
          _activeFallAlerts.add(key);
        }

        // 호출 알림
        if (currentLog.callButton == 1 &&
            !_dismissedLogIds.contains(currentLog.id)) {
          _activeCallAlerts.add(key);
        }
      }
    });

    _bedStatusList = bedMap.values.toList();
    _bedStatusList.sort((a, b) => a['roomId'].compareTo(b['roomId']));
  }

  void _onConfirmPressed(String bedKey, String type, int logId) {
    setState(() {
      if (type == 'fall') {
        _activeFallAlerts.remove(bedKey);
      } else if (type == 'call') {
        _activeCallAlerts.remove(bedKey);
      }
      _dismissedLogIds.add(logId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('확인 처리되었습니다.'), duration: Duration(seconds: 1)),
    );
  }

  void _navigateToMonitor(String bedId) {
    try {
      final patient = _allPatients.firstWhere((p) => p.bedId == bedId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BedMonitorScreen(patient: patient),
        ),
      );
    } catch (e) {
      debugPrint("Error navigating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('전체 침대 현황'),
            Text('마지막 갱신: $_lastUpdateTime',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _initData)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bedStatusList.isEmpty
              ? const Center(child: Text('등록된 환자가 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _bedStatusList.length,
                  itemBuilder: (context, index) {
                    final bedData = _bedStatusList[index];
                    final String bedKey = bedData['key'];
                    final SensorDataModel? currentLog = bedData['currentLog'];
                    final String? lastFallTime = bedData['lastFallTime'];

                    // 활성 알림 여부
                    final bool isFallAlert = _activeFallAlerts.contains(bedKey);
                    final bool isCallAlert = _activeCallAlerts.contains(bedKey);

                    // 현재 이벤트 타입 확인 (1: 주의, 2: 낙상)
                    int fallType = 0;
                    if (currentLog != null) {
                      fallType = currentLog.fallEvent;
                    }

                    // 카드 색상 결정
                    Color cardColor = Colors.white;
                    if (isFallAlert) {
                      // 2(낙상)이면 빨간색, 1(주의)이면 주황/노란색
                      cardColor = fallType == 2
                          ? Colors.red.shade50
                          : Colors.orange.shade50;
                    } else if (isCallAlert) {
                      cardColor = Colors.blue.shade50; // 호출은 파란색 계열로 변경 (구분 위해)
                    }

                    return Card(
                      elevation: (isFallAlert || isCallAlert) ? 4 : 1,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isFallAlert
                            ? BorderSide(
                                color:
                                    fallType == 2 ? Colors.red : Colors.orange,
                                width: 2)
                            : (isCallAlert
                                ? const BorderSide(color: Colors.blue, width: 2)
                                : BorderSide.none),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () => _navigateToMonitor(bedData['bedId']),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${bedData['roomId']}호 - ${bedData['bedId']}베드',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '환자: ${bedData['patientName']}',
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  // 상태 배지 (파라미터 추가)
                                  _buildStatusBadge(
                                      isFallAlert, isCallAlert, fallType),
                                ],
                              ),
                              const Divider(),

                              _buildInfoRow(
                                icon: Icons.access_time,
                                label: "최근 수신:",
                                value: currentLog?.timestamp
                                        .replaceAll('T', ' ') ??
                                    "데이터 없음",
                              ),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                icon: Icons.history_toggle_off,
                                label: "마지막 낙상:",
                                value: lastFallTime?.replaceAll('T', ' ') ??
                                    "기록 없음",
                                textColor: lastFallTime != null
                                    ? Colors.red[700]
                                    : Colors.grey,
                              ),

                              // [UI 변경] 낙상/주의 알림 버튼 분기 처리
                              if (isFallAlert && currentLog != null) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: fallType == 2
                                      // Case 2: 낙상 -> 빨간색 비상 버튼
                                      ? ElevatedButton.icon(
                                          onPressed: () => _onConfirmPressed(
                                              bedKey, 'fall', currentLog.id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon: const Icon(
                                              Icons.warning_amber_rounded),
                                          label: const Text("위험 비상 해제 (확인)"),
                                        )
                                      // Case 1: 주의 -> 주황색 확인 버튼
                                      : ElevatedButton.icon(
                                          onPressed: () => _onConfirmPressed(
                                              bedKey, 'fall', currentLog.id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon: const Icon(
                                              Icons.check_circle_outline),
                                          label: const Text("주의 감지 확인"),
                                        ),
                                )
                              ],

                              if (isCallAlert &&
                                  !isFallAlert &&
                                  currentLog != null) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _onConfirmPressed(
                                        bedKey, 'call', currentLog.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon:
                                        const Icon(Icons.notifications_active),
                                    label: const Text("호출 확인 및 해제"),
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // 배지 표시 로직 수정
  Widget _buildStatusBadge(bool isFallAlert, bool isCallAlert, int fallType) {
    String text = "정상";
    Color color = Colors.green.shade100;
    Color textColor = Colors.green.shade800;

    if (isFallAlert) {
      if (fallType == 2) {
        text = "낙상 발생";
        color = Colors.red;
        textColor = Colors.white;
      } else {
        text = "주의 상태"; // fallType == 1
        color = Colors.orange;
        textColor = Colors.white;
      }
    } else if (isCallAlert) {
      text = "호출 중";
      color = Colors.blue;
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                color: textColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
