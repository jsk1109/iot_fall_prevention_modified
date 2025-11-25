import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:iot_fall_prevention/models/patient_model.dart';
import 'package:iot_fall_prevention/models/ultrasonic_data.dart';
import 'package:iot_fall_prevention/services/api_service.dart';
import 'package:iot_fall_prevention/widgets/bubble_painter.dart';
import 'package:iot_fall_prevention/widgets/heatmap_painter.dart';

class BedMonitorScreen extends StatefulWidget {
  final Patient patient;

  const BedMonitorScreen({super.key, required this.patient});

  @override
  State<BedMonitorScreen> createState() => _BedMonitorScreenState();
}

class _BedMonitorScreenState extends State<BedMonitorScreen> {
  List<UltrasonicU4Response> _history = [];
  bool _isLoading = true;
  Timer? _timer;

  final List<SensorInfo> _sensorInfos = [
    SensorInfo(id: 'U1', label: '상단 좌측', color: Colors.blue),
    SensorInfo(id: 'U2', label: '상단 우측', color: Colors.red),
    SensorInfo(id: 'U3', label: '하단 좌측', color: Colors.green),
    SensorInfo(id: 'U4', label: '하단 우측', color: Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _timer =
        Timer.periodic(const Duration(seconds: 3), (timer) => _fetchHistory());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    try {
      final data = await ApiService.getUltrasonicHistory(widget.patient.bedId,
          limit: 50);
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  List<double> _calculateOccupancy(UltrasonicU4Response log) {
    double convert(int value) {
      const double maxDist = 150.0;
      double v = value.toDouble();
      if (v > maxDist) return 0.0;
      return (maxDist - v) / maxDist;
    }

    return [convert(log.u1), convert(log.u2), convert(log.u3), convert(log.u4)];
  }

  @override
  Widget build(BuildContext context) {
    final latestLog = _history.isNotEmpty
        ? _history.last
        : UltrasonicU4Response(
            dataId: 0,
            timestamp: '',
            nursinghomeId: '',
            roomId: '',
            bedId: '',
            callButton: 0,
            fallEvent: 0,
            u1: 0,
            u2: 0,
            u3: 0,
            u4: 0);

    final occupancy = _calculateOccupancy(latestLog);

    return Scaffold(
      appBar: AppBar(
        title:
            Text('${widget.patient.patientName} (${widget.patient.bedId}베드)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(latestLog),
                  const SizedBox(height: 24),
                  const Text("센서 데이터 (라인 차트)",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: LineChart(_buildLineChartData()),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text("환자 점유율 (히트맵)",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: CustomPaint(
                                  painter:
                                      HeatmapPainter(occupancyData: occupancy),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            const Text("센서 겹침 (버블 차트)",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey)),
                                child: CustomPaint(
                                  painter: BubblePainter(
                                    occupancyData: occupancy,
                                    sensors: _sensorInfos,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(UltrasonicU4Response log) {
    bool isFall = log.fallEvent == 2;
    return Card(
      color: isFall ? Colors.red.shade50 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(isFall ? Icons.warning : Icons.check_circle,
                size: 40, color: isFall ? Colors.red : Colors.blue),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isFall ? "낙상 감지!" : "정상 모니터링 중",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text("최근 업데이트: ${log.timestamp.replaceAll('T', ' ')}"),
                Text("센서값: [${log.u1}, ${log.u2}, ${log.u3}, ${log.u4}] cm"),
              ],
            )
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: const FlGridData(show: true),
      titlesData: const FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
          show: true, border: Border.all(color: Colors.grey.shade300)),
      minY: 0,
      maxY: 200,
      lineBarsData: [
        _buildLine(0, Colors.blue),
        _buildLine(1, Colors.red),
        _buildLine(2, Colors.green),
        _buildLine(3, Colors.purple),
      ],
    );
  }

  LineChartBarData _buildLine(int sensorIndex, Color color) {
    List<FlSpot> spots = [];

    for (int i = 0; i < _history.length; i++) {
      int val = 0;
      switch (sensorIndex) {
        case 0:
          val = _history[i].u1;
          break;
        case 1:
          val = _history[i].u2;
          break;
        case 2:
          val = _history[i].u3;
          break;
        case 3:
          val = _history[i].u4;
          break;
      }
      spots.add(FlSpot(i.toDouble(), val.toDouble()));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}
