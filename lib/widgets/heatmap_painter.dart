import 'package:flutter/material.dart';

class HeatmapPainter extends CustomPainter {
  final List<double> occupancyData;

  HeatmapPainter({required this.occupancyData});

  @override
  void paint(Canvas canvas, Size size) {
    if (occupancyData.length != 4) return;

    double w = size.width / 2;
    double h = size.height / 2;

    List<Offset> offsets = [
      const Offset(0, 0),
      Offset(w, 0),
      Offset(0, h),
      Offset(w, h),
    ];

    for (int i = 0; i < 4; i++) {
      double value = occupancyData[i];
      Color color = Color.lerp(Colors.green.shade100, Colors.red, value) ??
          Colors.transparent;

      Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(offsets[i].dx, offsets[i].dy, w, h),
        paint,
      );

      Paint borderPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(
        Rect.fromLTWH(offsets[i].dx, offsets[i].dy, w, h),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.occupancyData != occupancyData;
  }
}
