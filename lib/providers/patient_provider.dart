import 'package:flutter/material.dart';
import '../models/patient.dart';

// 환자 정보를 관리하는 Provider 클래스
class PatientProvider with ChangeNotifier {
  // 가라데이터 환자 목록
  final List<Patient> _patients = [
    Patient(
      id: '1',
      name: '김철수',
      age: 75,
      gender: '남성',
      room: '301',
      diagnosis: '고혈압',
      riskLevel: '높음',
      status: '정상',
      isHighRisk: true,
    ),
    Patient(
      id: '2',
      name: '이영희',
      age: 82,
      gender: '여성',
      room: '302',
      diagnosis: '당뇨병',
      riskLevel: '중간',
      status: '주의',
      isHighRisk: false,
    ),
    Patient(
      id: '3',
      name: '박지민',
      age: 68,
      gender: '남성',
      room: '303',
      diagnosis: '심장질환',
      riskLevel: '낮음',
      status: '정상',
      isHighRisk: false,
    ),
    Patient(
      id: '4',
      name: '최수진',
      age: 79,
      gender: '여성',
      room: '304',
      diagnosis: '폐렴',
      riskLevel: '높음',
      status: '위험',
      isHighRisk: true,
    ),
    Patient(
      id: '5',
      name: '정민수',
      age: 85,
      gender: '남성',
      room: '305',
      diagnosis: '관절염',
      riskLevel: '중간',
      status: '정상',
      isHighRisk: false,
    ),
  ];

  // 환자 목록 getter
  List<Patient> get patients => _patients;

  // 환자 추가
  void addPatient(Patient patient) {
    _patients.add(patient);
    notifyListeners();
  }

  // 환자 삭제
  void removePatient(String id) {
    _patients.removeWhere((patient) => patient.id == id);
    notifyListeners();
  }

  // 환자 정보 업데이트
  void updatePatient(Patient updatedPatient) {
    final index =
        _patients.indexWhere((patient) => patient.id == updatedPatient.id);
    if (index != -1) {
      _patients[index] = updatedPatient;
      notifyListeners();
    }
  }

  // 환자 상태 업데이트
  void updatePatientStatus(String id, String status) {
    final index = _patients.indexWhere((patient) => patient.id == id);
    if (index != -1) {
      final patient = _patients[index];
      _patients[index] = Patient(
        id: patient.id,
        name: patient.name,
        age: patient.age,
        gender: patient.gender,
        room: patient.room,
        diagnosis: patient.diagnosis,
        riskLevel: patient.riskLevel,
        status: status,
        isHighRisk: patient.isHighRisk,
      );
      notifyListeners();
    }
  }
}
