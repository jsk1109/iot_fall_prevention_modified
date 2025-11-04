import 'package:flutter/material.dart'; // [핵심 수정] 콜론(:) 추가
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

// 패키지 절대 경로 사용
import 'package:iot_fall_prevention/models/ultrasonic_data.dart' as model;
import 'package:iot_fall_prevention/services/api_service.dart';
import 'package:iot_fall_prevention/models/patient_model.dart';
import 'package:iot_fall_prevention/services/heatmap_generator.dart';
import 'package:iot_fall_prevention/widgets/heatmap_painter.dart';
import 'package:iot_fall_prevention/widgets/bubble_painter.dart';

class SensorInfo {
  final String id;
  final Color color;
  final String name;

  SensorInfo({required this.id, required this.color, required this.name});
}

class BedMonitorScreen extends StatefulWidget {
  final Patient patient;

  const BedMonitorScreen({super.key, required this.patient});

  @override
  State<BedMonitorScreen> createState() => _BedMonitorScreenState();
}

class _BedMonitorScreenState extends State<BedMonitorScreen> {
  late Future<List<model.UltrasonicU4Response>> _historyFuture;

  final List<SensorInfo> sensors = [
    SensorInfo(id: 'ESP32-1', color: Colors.blue, name: "상단 좌측 (U1)"),
    SensorInfo(id: 'ESP32-2', color: Colors.red, name: "상단 우측 (U2)"),
    SensorInfo(id: 'ESP32-3', color: Colors.green, name: "하단 좌측 (U3)"),
    SensorInfo(id: 'ESP32-4', color: Colors.purple, name: "하단 우측 (U4)"),
  ];

  int _selectedDurationMinutes = 60;
  final Map<int, String> _durationOptions = {
    5: '최근 5분',
    10: '최근 10분',
    60: '최근 1시간',
    0: '최근 100개',
  };

  final HeatmapGenerator _heatmapGenerator = HeatmapGenerator();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = ApiService.getUltrasonicHistory(widget.patient.bedId,
          durationMinutes: _selectedDurationMinutes, limit: 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.patient.patientName} (${widget.patient.roomId}/${widget.patient.bedId}) 모니터링'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadHistory,
              tooltip: '새로고침'),
        ],
      ),
      body: FutureBuilder<List<model.UltrasonicU4Response>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('데이터 로딩 실패: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('센서 데이터가 없습니다.'));
          }

          final historyData = snapshot.data!;
          final model.UltrasonicU4Response latestData = historyData.last;

          final occupancyValues = _heatmapGenerator
              .getNormalizedOccupancy(latestData.ultrasonicData);
          final heatmapGrid =
              _heatmapGenerator.generateHeatmapGrid(occupancyValues);

          const double bedAspectRatio = 1.8;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('환자 점유율 (히트맵)'),
                _buildHeatmap(heatmapGrid, bedAspectRatio),
                const SizedBox(height: 32),
                _buildSectionTitle('센서 겹침 (버블 차트)'),
                _buildBubbleChart(occupancyValues, bedAspectRatio),
                const SizedBox(height: 32),
                _buildLineChartSection(historyData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildHeatmap(List<List<double>> heatmapGrid, double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blueGrey[50],
        ),
        child: CustomPaint(
          painter: HeatmapPainter(gridData: heatmapGrid),
          child: _buildSensorLabels(),
        ),
      ),
    );
  }

  Widget _buildBubbleChart(List<double> occupancy, double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blueGrey[50],
        ),
        child: CustomPaint(
          painter: BubblePainter(occupancyData: occupancy, sensors: sensors),
          child: _buildSensorLabels(),
        ),
      ),
    );
  }

  Widget _buildLineChartSection(List<model.UltrasonicU4Response> historyData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('센서 데이터 (라인 차트)'),
            DropdownButton<int>(
              value: _selectedDurationMinutes,
              items: _durationOptions.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null && newValue != _selectedDurationMinutes) {
                  setState(() {
                    _selectedDurationMinutes = newValue;
                  });
                  _loadHistory();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegend(),
        const SizedBox(height: 16),
        _buildChart(historyData),
      ],
    );
  }

  Widget _buildSensorLabels() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSensorLabel(sensors[0]),
            _buildSensorLabel(sensors[1]),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSensorLabel(sensors[2]),
            _buildSensorLabel(sensors[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorLabel(SensorInfo sensor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        sensor.name,
        style: TextStyle(
            color: sensor.color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: sensors.map((sensor) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: sensor.color),
            const SizedBox(width: 4),
            Text('${sensor.name} (${sensor.id})',
                style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChart(List<model.UltrasonicU4Response> historyData) {
    final List<LineChartBarData> lineBarsData = [];
    double minY = double.maxFinite;
    double maxY = double.minPositive;

    for (int sensorIndex = 0; sensorIndex < sensors.length; sensorIndex++) {
      final sensorInfo = sensors[sensorIndex];
      final List<FlSpot> spots = [];

      for (int i = 0; i < historyData.length; i++) {
        final data = historyData[i];
        final distance = data.ultrasonicData[sensorIndex];

        if (distance != null && distance > 0) {
          spots.add(FlSpot(i.toDouble(), distance.toDouble()));
          if (distance < minY) minY = distance.toDouble();
          if (distance > maxY) maxY = distance.toDouble();
        }
      }

      if (spots.isNotEmpty) {
        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: sensorInfo.color.withOpacity(0.6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                      radius: 2,
                      color: barData.color?.withOpacity(1.0) ?? Colors.blue),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    if (minY == double.maxFinite) minY = 0;
    if (maxY == double.minPositive) maxY = 100;
    double range = maxY - minY;
    if (range < 20 && maxY > 0) {
      double mid = (maxY + minY) / 2;
      minY = math.max(0, mid - 10);
      maxY = mid + 10;
    } else {
      minY = math.max(0, minY - 10);
      maxY = maxY + 10;
    }

    if (lineBarsData.isEmpty) {
      return const SizedBox(
          height: 200, child: Center(child: Text("그래프 데이터 부족")));
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (historyData.length / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < historyData.length) {
                    final timestamp = historyData[index].timestamp;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                          DateFormat('MM/dd HH:mm').format(timestamp.toLocal()),
                          style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()} cm',
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          borderData:
              FlBorderData(show: true, border: Border.all(color: Colors.grey)),
          lineBarsData: lineBarsData,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (LineBarSpot touchedSpot) =>
                  Colors.blueGrey.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final sensorInfo = sensors[barSpot.barIndex];
                  return LineTooltipItem(
                    '${sensorInfo.name}: ${flSpot.y.toInt()} cm\n',
                    TextStyle(
                        color: sensorInfo.color.withOpacity(1.0),
                        fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
