import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math; // Y축 범위 계산용
import '../models/ultrasonic_data.dart';
import '../services/api_service.dart';
import '../models/patient_model.dart';

// 센서 ID와 메타데이터(색상, 이름 등)를 관리하는 클래스
class SensorInfo {
  final String id;
  final Color color;
  final String name; // 예: "상단 좌측"

  SensorInfo({required this.id, required this.color, required this.name});
}

class BedMonitorScreen extends StatefulWidget {
  final Patient patient; // StaffScreen에서 전달받는 환자 정보

  const BedMonitorScreen({super.key, required this.patient});

  @override
  State<BedMonitorScreen> createState() => _BedMonitorScreenState();
}

class _BedMonitorScreenState extends State<BedMonitorScreen> {
  // 서버로부터 받을 데이터의 타입 명시 (UltrasonicData 사용 확인)
  late Future<Map<String, List<UltrasonicData>>> _historyFuture;

  // 센서 정보 정의 (ID 순서 중요: 1, 2, 3, 4)
  final List<SensorInfo> sensors = [
    SensorInfo(id: 'ESP32-1', color: Colors.blue, name: "상단 좌측"),
    SensorInfo(id: 'ESP32-2', color: Colors.red, name: "상단 우측"),
    SensorInfo(id: 'ESP32-3', color: Colors.green, name: "하단 좌측"),
    SensorInfo(id: 'ESP32-4', color: Colors.purple, name: "하단 우측"),
  ];

  // --- 시간 범위 선택 관련 상태 변수 ---
  int _selectedDurationMinutes = 60; // 기본값 10분
  final Map<int, String> _durationOptions = {
    5: '최근 5분',
    10: '최근 10분',
    60: '최근 1시간',
    0: '최근 1000개', // 서버 API와 의미 일치 (0 = limit 기반)
  };
  // ---

  @override
  void initState() {
    super.initState();
    _loadHistory(); // 화면이 처음 로드될 때 데이터 요청
  }

  // 서버에 센서 데이터 기록을 요청하는 함수 (선택된 시간 범위 사용)
  void _loadHistory() {
    setState(() {
      _historyFuture = ApiService.getUltrasonicHistory(widget.patient.bedId,
          durationMinutes: _selectedDurationMinutes, // 선택된 시간 범위 전달
          limit: 1000 // durationMinutes가 0일 때 사용할 최대 개수
          );
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
      body: FutureBuilder<Map<String, List<UltrasonicData>>>(
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
          final latestData = _getLatestData(historyData);

          return LayoutBuilder(builder: (context, constraints) {
            // 침대 시각화 영역 비율 고정 (2x2 그리드 유지 위해)
            const double bedAspectRatio = 1.8; // 이 값을 조절하여 높이 변경 가능

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('최근 센서 값 시각화',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // 수정된 시각화 위젯 호출 (Column/Row 기반)
                  _buildBedVisualization(latestData, bedAspectRatio),
                  const SizedBox(height: 32),
                  // 시간 범위 선택 UI 포함된 Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('센서 데이터 그래프',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: _selectedDurationMinutes,
                        items: _durationOptions.entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null &&
                              newValue != _selectedDurationMinutes) {
                            setState(() {
                              _selectedDurationMinutes = newValue;
                            });
                            _loadHistory(); // 선택 변경 시 데이터 다시 로드
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLegend(),
                  const SizedBox(height: 16),
                  // 개선된 그래프 위젯 호출
                  _buildChart(historyData),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  // --- 침대 시각화 위젯 (Column/Row 기반) ---
  Widget _buildBedVisualization(
      Map<String, UltrasonicData?> latestData, double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blueGrey[50],
        ),
        child: Column(
          children: [
            // 첫 번째 행 (센서 1, 센서 2)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child:
                          _buildSensorInfoBox(latestData, sensors[0])), // 상단 좌측
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          _buildSensorInfoBox(latestData, sensors[1])), // 상단 우측
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 두 번째 행 (센서 3, 센서 4)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child:
                          _buildSensorInfoBox(latestData, sensors[2])), // 하단 좌측
                  const SizedBox(width: 8),
                  Expanded(
                      child:
                          _buildSensorInfoBox(latestData, sensors[3])), // 하단 우측
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 개별 센서 정보 박스를 만드는 Helper 위젯 ---
  Widget _buildSensorInfoBox(
      Map<String, UltrasonicData?> latestData, SensorInfo sensorInfo) {
    final data = latestData[sensorInfo.id];
    final distanceText = data != null ? '${data.distance} cm' : 'N/A';
    String positionName = sensorInfo.name;

    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize =
        screenWidth < 400 ? 14 : (screenWidth < 600 ? 16 : 18);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: sensorInfo.color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white, // 배경색
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            positionName,
            style: TextStyle(
              fontSize: baseFontSize * 0.7,
              color: sensorInfo.color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            distanceText,
            style: TextStyle(
              fontSize: baseFontSize,
              color: sensorInfo.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (data != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                DateFormat('HH:mm:ss').format(data.timestamp.toLocal()),
                style: TextStyle(
                    fontSize: baseFontSize * 0.5, color: Colors.grey[600]),
              ),
            )
        ],
      ),
    );
  }

  // 그래프 범례 위젯
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

  // 라인 차트 위젯 (투명도 및 가독성 개선)
  Widget _buildChart(Map<String, List<UltrasonicData>> historyData) {
    final List<LineChartBarData> lineBarsData = [];
    double minY = double.maxFinite;
    double maxY = double.minPositive;
    int dataCount = 0;
    DateTime? firstTimestamp;

    for (int i = 0; i < sensors.length; i++) {
      final sensorInfo = sensors[i];
      final dataList = historyData[sensorInfo.id];

      if (dataList != null && dataList.isNotEmpty) {
        if (firstTimestamp == null ||
            dataList.first.timestamp.isBefore(firstTimestamp!)) {
          firstTimestamp = dataList.first.timestamp;
        }

        final List<FlSpot> spots = [];
        for (int j = 0; j < dataList.length; j++) {
          final data = dataList[j];
          if (data.distance > 0) {
            spots.add(FlSpot(j.toDouble(), data.distance.toDouble()));
            if (data.distance < minY) minY = data.distance.toDouble();
            if (data.distance > maxY) maxY = data.distance.toDouble();
          }
        }

        if (spots.isNotEmpty) {
          dataCount = math.max(dataCount, spots.length);
          lineBarsData.add(
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: sensorInfo.color.withOpacity(0.6), // 투명도 적용
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                // 점 설정
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                        radius: 2,
                        color: barData.color?.withOpacity(1.0) ??
                            Colors.blue), // 점 크기 및 불투명 색상
              ),
              belowBarData: BarAreaData(show: false),
            ),
          );
        }
      }
    }

    // Y축 범위 자동 조정 개선
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

    // 그래프 위젯 반환
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
                interval: dataCount > 1 ? (dataCount / 5).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (firstTimestamp != null && value.toInt() < dataCount) {
                    final currentTimestamp = firstTimestamp!.add(Duration(
                        milliseconds: (value * 100).toInt())); // 0.1초 간격 가정
                    final interval = meta.appliedInterval ??
                        (dataCount > 1 ? (dataCount / 5).ceilToDouble() : 1);
                    // 간격에 맞는 위치 또는 첫/마지막 위치에만 레이블 표시
                    if (value == 0 ||
                        value % interval == 0 ||
                        value.toInt() == dataCount - 1) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8.0,
                        child: Text(
                            DateFormat('HH:mm:ss')
                                .format(currentTimestamp.toLocal()),
                            style: const TextStyle(fontSize: 10)),
                      );
                    }
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
              getTooltipColor: (LineBarSpot touchedSpot) =>
                  Colors.blueGrey.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final sensorInfo = sensors[barSpot.barIndex];
                  return LineTooltipItem(
                    '${sensorInfo.name}: ${flSpot.y.toInt()} cm\n',
                    // 툴팁 텍스트는 불투명하게
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

  // 각 센서 ID별 최신 데이터를 추출하는 함수
  Map<String, UltrasonicData?> _getLatestData(
      Map<String, List<UltrasonicData>> history) {
    final Map<String, UltrasonicData?> latest = {};
    for (var sensor in sensors) {
      final dataList = history[sensor.id];
      if (dataList != null && dataList.isNotEmpty) {
        latest[sensor.id] = dataList.last;
      } else {
        latest[sensor.id] = null;
      }
    }
    return latest;
  }
} // _BedMonitorScreenState 클래스 끝

