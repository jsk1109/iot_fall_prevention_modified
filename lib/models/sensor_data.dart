class SensorData {
  final int id;
  // nursinghome_id는 이 API 응답에 포함되지 않으므로 제거합니다.
  final String roomId;
  final String? bedId; // bed_id는 DB에서 NULL일 수 있으므로 String? (nullable)로 선언합니다.
  final String sensorId;
  final DateTime timestamp;
  final String value; // 예: "낙상 감지", "환자 호출"
  final String type; // 예: "fall", "button"

  SensorData({
    required this.id,
    required this.roomId,
    this.bedId, // nullable 이므로 required가 아닙니다.
    required this.sensorId,
    required this.timestamp,
    required this.value,
    required this.type,
  });

  // JSON 데이터를 받아서 SensorData 객체를 만드는 생성자입니다.
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'],
      // 서버가 보내주는 camelCase 키에 정확히 맞춰줍니다.
      roomId: json['roomId'],
      bedId: json['bedId'],
      sensorId: json['sensorId'],
      timestamp: DateTime.parse(json['timestamp']),
      value: json['value'],
      type: json['type'],
    );
  }
}
