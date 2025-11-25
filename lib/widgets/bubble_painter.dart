import 'package:flutter/material.dart';
import 'dart:math' as math;

// [수정됨] SensorInfo 클래스를 여기서 직접 정의합니다.
class SensorInfo {
  final String id;
  final String label;
  final Color color;

  SensorInfo({required this.id, required this.label, required this.color});
}

class BubblePainter extends CustomPainter {
  final List<double> occupancyData; // [P1, P2, P3, P4] (0.0 ~ 1.0)
  final List<SensorInfo> sensors;

  BubblePainter({required this.occupancyData, required this.sensors});

  @override
  void paint(Canvas canvas, Size size) {
    // 데이터 개수가 4개가 아니면 그리지 않음
    if (occupancyData.length != 4) return;

    double maxRadius = math.min(size.width, size.height) * 0.35;

    // 4개 센서의 위치 좌표 (화면 분할)
    List<Offset> positions = [
      Offset(size.width * 0.30, size.height * 0.30), // U1 (좌상)
      Offset(size.width * 0.70, size.height * 0.30), // U2 (우상)
      Offset(size.width * 0.30, size.height * 0.70), // U3 (좌하)
      Offset(size.width * 0.70, size.height * 0.70), // U4 (우하)
    ];

    for (int i = 0; i < 4; i++) {
      double occupancy = occupancyData[i];
      if (occupancy <= 0) continue;

      // 값에 따라 원 크기 결정
      double radius = maxRadius * occupancy;

      // 내부 채우기 (반투명)
      final paint = Paint()
        ..color = sensors[i].color.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(positions[i], radius, paint);

      // 테두리 그리기
      final borderPaint = Paint()
        ..color = sensors[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(positions[i], radius, borderPaint);

      // (선택사항) 센서 라벨 그리기
      _drawText(canvas, sensors[i].label, positions[i]);
    }
  }

  // 텍스트 그리기 헬퍼 함수
  void _drawText(Canvas canvas, String text, Offset center) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
          color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.occupancyData != occupancyData;
  }
}
