import 'package:flutter/material.dart';
import 'package:iot_fall_prevention/services/heatmap_generator.dart';

class HeatmapPainter extends CustomPainter {
  final List<List<double>> gridData;
  late final int gridSize;

  HeatmapPainter({required this.gridData}) {
    // 그리드 크기를 입력된 데이터로부터 동적으로 설정
    gridSize = gridData.isNotEmpty ? gridData.length : 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (gridData.isEmpty) return;

    final double cellWidth = size.width / gridSize;
    final double cellHeight = size.height / gridSize;

    Color getColor(double occupancy) {
      if (occupancy >= 0.8) {
        return Colors.red.shade700; // 80% 이상 (매우 높음)
      } else if (occupancy >= 0.6) {
        return Colors.yellow.shade600; // 60% - 80%
      } else if (occupancy >= 0.4) {
        return Colors.green.shade500; // 40% - 60% (중간)
      } else if (occupancy >= 0.2) {
        return Colors.cyan.shade400; // 20% - 40%
      } else {
        return Colors.blue.shade300; // 20% 미만 (낮음)
      }
    }

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        double occupancy = gridData[y][x];

        final color = getColor(occupancy);
        final paint = Paint()..color = color;

        final rect = Rect.fromLTWH(
          x * cellWidth,
          (gridSize - 1 - y) * cellHeight, // Y축 반전 (0,0을 좌측 하단으로)
          cellWidth,
          cellHeight,
        );

        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.gridData != gridData;
  }
}
