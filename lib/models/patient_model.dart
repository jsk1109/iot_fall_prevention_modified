class Patient {
  final String patientId;
  final String patientName;
  final String roomId;
  final String bedId;

  Patient({
    required this.patientId,
    required this.patientName,
    required this.roomId,
    required this.bedId,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: json['patient_id'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      bedId: json['bed_id'] as String? ?? '',
    );
  }
}
