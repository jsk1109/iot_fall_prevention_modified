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

  final Set<int> _confirmedLogIds = {};

  Timer? _timer;
  bool _isLoading = true;
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
        });
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    }
  }

  void _processBedData() {
    final Map<String, Map<String, dynamic>> bedMap = {};

    for (var patient in _allPatients) {
      final key = '${patient.roomId}-${patient.bedId}';
      bedMap[key] = {
        'patientName': patient.patientName,
        'roomId': patient.roomId,
        'bedId': patient.bedId,
        'currentLog': null,
        'lastFallTime': null,
        'lastFallLogId': null,
      };
    }

    for (var log in _rawLogs) {
      final key = '${log.roomId}-${log.bedId}';
      if (bedMap.containsKey(key)) {
        if (bedMap[key]!['currentLog'] == null) {
          bedMap[key]!['currentLog'] = log;
        }
        if (log.fallEvent == 2 && bedMap[key]!['lastFallTime'] == null) {
          bedMap[key]!['lastFallTime'] = log.timestamp;
          bedMap[key]!['lastFallLogId'] = log.id;
        }
      }
    }

    _bedStatusList = bedMap.values.toList();
    _bedStatusList.sort((a, b) => a['roomId'].compareTo(b['roomId']));
  }

  void _onConfirmPressed(int logId) {
    setState(() {
      _confirmedLogIds.add(logId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('확인 처리되었습니다.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // [수정됨] bedId 대신 Patient 객체를 찾아 전달하도록 수정
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
        title: const Text('전체 침대 현황'),
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
                    final SensorDataModel? currentLog = bedData['currentLog'];

                    final String? lastFallTime = bedData['lastFallTime'];
                    final int? lastFallLogId = bedData['lastFallLogId'];

                    bool isCurrentFall = false;
                    bool isDanger = false;

                    if (currentLog != null) {
                      isCurrentFall = currentLog.fallEvent == 2;
                      isDanger = isCurrentFall &&
                          !_confirmedLogIds.contains(currentLog.id);
                    }

                    final bool isLastFallConfirmed = lastFallLogId != null &&
                        _confirmedLogIds.contains(lastFallLogId);

                    return Card(
                      elevation: isDanger ? 4 : 1,
                      color: isDanger ? Colors.red.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isDanger
                            ? const BorderSide(color: Colors.red, width: 2)
                            : BorderSide.none,
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
                                  _buildStatusBadge(
                                      currentLog, isDanger, isCurrentFall),
                                ],
                              ),
                              const Divider(),
                              _buildInfoRow(
                                icon: Icons.access_time,
                                label: "최근 데이터:",
                                value: currentLog?.timestamp
                                        .replaceAll('T', ' ') ??
                                    "데이터 없음",
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoRow(
                                      icon: Icons.history_toggle_off,
                                      label: "마지막 위험:",
                                      value:
                                          lastFallTime?.replaceAll('T', ' ') ??
                                              "기록 없음",
                                      textColor: lastFallTime != null
                                          ? Colors.red[700]
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (lastFallLogId != null &&
                                      !isLastFallConfirmed)
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _onConfirmPressed(lastFallLogId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade100,
                                          foregroundColor:
                                              Colors.orange.shade900,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                        ),
                                        child: const Text("확인",
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    )
                                  else if (isLastFallConfirmed)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.check_circle,
                                          color: Colors.green, size: 20),
                                    )
                                ],
                              ),
                              if (isDanger) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _onConfirmPressed(currentLog!.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(
                                        Icons.notifications_off_outlined),
                                    label: const Text("현재 낙상 알림 해제"),
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

  Widget _buildStatusBadge(
      SensorDataModel? log, bool isDanger, bool isCurrentFall) {
    String text = "데이터 없음";
    Color color = Colors.grey;
    Color textColor = Colors.white;

    if (log != null) {
      if (isDanger) {
        text = "낙상 감지";
        color = Colors.red;
      } else if (isCurrentFall) {
        text = "조치 완료";
        color = Colors.green;
      } else {
        text = "정상";
        color = Colors.green.shade100;
        textColor = Colors.green.shade800;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
