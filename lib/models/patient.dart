class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String room;
  final String diagnosis;
  final String riskLevel;
  final String status;
  final bool isHighRisk;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.room,
    required this.diagnosis,
    required this.riskLevel,
    required this.status,
    required this.isHighRisk,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      room: json['room'] as String,
      diagnosis: json['diagnosis'] as String,
      riskLevel: json['riskLevel'] as String,
      status: json['status'] as String,
      isHighRisk: json['isHighRisk'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'room': room,
      'diagnosis': diagnosis,
      'riskLevel': riskLevel,
      'status': status,
      'isHighRisk': isHighRisk,
    };
  }
}
