import 'package:flutter/material.dart';
import 'dart:math' as math;
// SensorInfo 클래스를 bed_monitor_screen.dart에서 가져옵니다.
import 'package:iot_fall_prevention/screens/bed_monitor_screen.dart';

class BubblePainter extends CustomPainter {
  final List<double> occupancyData; // [P1, P2, P3, P4] (0.0 ~ 1.0)
  final List<SensorInfo> sensors;

  BubblePainter({required this.occupancyData, required this.sensors});

  @override
  void paint(Canvas canvas, Size size) {
    if (occupancyData.length != 4) return;

    double maxRadius = math.min(size.width, size.height) * 0.35;

    List<Offset> positions = [
      Offset(size.width * 0.35, size.height * 0.35), // U1 (상단 좌측)
      Offset(size.width * 0.65, size.height * 0.35), // U2 (상단 우측)
      Offset(size.width * 0.35, size.height * 0.65), // U3 (하단 좌측)
      Offset(size.width * 0.65, size.height * 0.65), // U4 (하단 우측)
    ];

    for (int i = 0; i < 4; i++) {
      double occupancy = occupancyData[i];
      if (occupancy <= 0) continue; // 점유율 0 이하면 그리지 않음

      double radius = maxRadius * occupancy;

      final paint = Paint()
        ..color = sensors[i].color.withOpacity(0.5) // 겹침을 위해 반투명
        ..style = PaintingStyle.fill;

      canvas.drawCircle(positions[i], radius, paint);

      final borderPaint = Paint()
        ..color = sensors[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(positions[i], radius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.occupancyData != occupancyData;
  }
}
