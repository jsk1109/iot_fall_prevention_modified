class UltrasonicU4Response {
  final int dataId;
  final DateTime timestamp;
  final String roomId;
  final String bedId;
  final bool callButton;
  final bool fallEvent;
  // u1, u2, u3, u4 값을 리스트로 묶어 받습니다.
  final List<int?> ultrasonicData;

  UltrasonicU4Response({
    required this.dataId,
    required this.timestamp,
    required this.roomId,
    required this.bedId,
    required this.callButton,
    required this.fallEvent,
    required this.ultrasonicData,
  });

  // 서버로부터 받은 JSON 데이터를 UltrasonicU4Response 객체로 변환
  factory UltrasonicU4Response.fromJson(Map<String, dynamic> json) {
    // ultrasonic_data 필드를 List<int?>로 파싱
    final List<dynamic> dataListDynamic = json['ultrasonic_data'] ?? [];
    final List<int?> dataList = dataListDynamic.map((e) => e as int?).toList();

    return UltrasonicU4Response(
      dataId: json['data_id'] as int? ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      roomId: json['room_id'] as String? ?? 'unknown',
      bedId: json['bed_id'] as String? ?? 'unknown',
      callButton: json['call_button'] as bool? ?? false,
      fallEvent: json['fall_event'] as bool? ?? false,
      ultrasonicData: dataList, // 4채널 통합 리스트 할당
    );
  }
}
