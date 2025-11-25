class SensorDataModel {
  final int id;
  final String timestamp;
  final String nursinghomeId;
  final String roomId;
  final String bedId;
  final int callButton;
  final int fallEvent;

  SensorDataModel({
    required this.id,
    required this.timestamp,
    required this.nursinghomeId,
    required this.roomId,
    required this.bedId,
    required this.callButton,
    required this.fallEvent,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    return SensorDataModel(
      id: json['id'],
      timestamp: json['timestamp'] ?? '',
      nursinghomeId: json['nursinghome_id'] ?? '',
      roomId: json['room_id'] ?? '',
      bedId: json['bed_id'] ?? '',
      callButton: json['call_button'] ?? 0,
      fallEvent: json['fall_event'] ?? 0,
    );
  }
}
