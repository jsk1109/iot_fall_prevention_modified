class UltrasonicData {
  final int id;
  final String sensorId;
  final int distance; // 서버 JSON의 'ultrasonic' 필드를 'distance'로 명명
  final DateTime timestamp;
  final String bedId; // 서버 JSON의 'bed_id' 필드

  UltrasonicData({
    required this.id,
    required this.sensorId,
    required this.distance,
    required this.timestamp,
    required this.bedId,
  });

  // 서버로부터 받은 JSON 데이터를 UltrasonicData 객체로 변환하는 팩토리 생성자
  factory UltrasonicData.fromJson(Map<String, dynamic> json) {
    // 각 필드의 값이 null일 경우를 대비하여 기본값 설정 (앱 비정상 종료 방지)
    return UltrasonicData(
      id: json['id'] as int? ?? 0, // JSON의 'id' 필드 (정수형)
      sensorId: json['sensor_id'] as String? ??
          'unknown', // JSON의 'sensor_id' 필드 (문자열)
      distance: json['ultrasonic'] as int? ?? 0, // JSON의 'ultrasonic' 필드 (정수형)
      // timestamp 파싱 오류 방지: null이거나 잘못된 형식이면 현재 시간 사용
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      bedId: json['bed_id'] as String? ?? 'unknown', // JSON의 'bed_id' 필드 (문자열)
    );
  }
}
