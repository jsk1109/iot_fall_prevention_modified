import 'dart:math';

class HeatmapGenerator {
  static const double maxDistance = 100.0;
  static const int gridSize = 10;

  // 4개 센서의 '점유율' (0.0 ~ 1.0)을 계산하는 공용 함수
  List<double> getNormalizedOccupancy(List<int?> distances) {
    if (distances.length != 4) return [0.0, 0.0, 0.0, 0.0];

    return distances.map((d) {
      if (d == null || d >= maxDistance) return 0.0;

      // Z축 정의: 환자의 점유율 (1 / 거리) -> (MaxDistance - D) / MaxDistance
      double occupancy = (maxDistance - d) / maxDistance;
      return max(0.0, min(1.0, occupancy)); // 0.0 ~ 1.0 범위 보장
    }).toList();
  }

  // 4개의 점유율 값을 10x10 그리드로 보간(Interpolation)
  List<List<double>> generateHeatmapGrid(List<double> normalizedOccupancy) {
    if (normalizedOccupancy.length != 4) {
      return List.generate(gridSize, (_) => List.filled(gridSize, 0.0));
    }

    List<List<double>> grid =
        List.generate(gridSize, (_) => List.filled(gridSize, 0.0));

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        double normalizedX = x / (gridSize - 1);
        double normalizedY = y / (gridSize - 1);

        // 상단 보간 (U1, U2)
        double pTop = (normalizedX * normalizedOccupancy[1]) + // U2
            ((1 - normalizedX) * normalizedOccupancy[0]); // U1
        // 하단 보간 (U3, U4)
        double pBottom = (normalizedX * normalizedOccupancy[3]) + // U4
            ((1 - normalizedX) * normalizedOccupancy[2]); // U3

        // 최종 Y축 보간
        double finalOccupancy =
            (normalizedY * pTop) + ((1 - normalizedY) * pBottom);

        grid[y][x] = finalOccupancy;
      }
    }
    return grid;
  }
}
