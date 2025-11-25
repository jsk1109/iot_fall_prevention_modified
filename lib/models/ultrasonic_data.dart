class UltrasonicU4Response {
  final int dataId;
  final String timestamp; // DateTime 대신 String으로 받아 처리가 쉽도록 변경
  final String nursinghomeId;
  final String roomId;
  final String bedId;
  final int callButton;
  final int fallEvent;
  // [누락되었던 센서 데이터 필드 추가]
  final int u1;
  final int u2;
  final int u3;
  final int u4;

  UltrasonicU4Response({
    required this.dataId,
    required this.timestamp,
    required this.nursinghomeId,
    required this.roomId,
    required this.bedId,
    required this.callButton,
    required this.fallEvent,
    required this.u1,
    required this.u2,
    required this.u3,
    required this.u4,
  });

  factory UltrasonicU4Response.fromJson(Map<String, dynamic> json) {
    return UltrasonicU4Response(
      dataId: json['data_id'] ?? 0,
      // null일 경우 빈 문자열 처리
      timestamp: json['timestamp']?.toString() ?? '',
      nursinghomeId: json['nursinghome_id'] ?? '',
      roomId: json['room_id'] ?? '',
      bedId: json['bed_id'] ?? '',
      callButton: json['call_button'] ?? 0,
      fallEvent: json['fall_event'] ?? 0,
      // 센서 값 파싱 (null이면 0으로 처리)
      u1: json['u1'] ?? 0,
      u2: json['u2'] ?? 0,
      u3: json['u3'] ?? 0,
      u4: json['u4'] ?? 0,
    );
  }
}
