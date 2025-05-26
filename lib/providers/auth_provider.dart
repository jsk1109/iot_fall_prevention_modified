import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// 사용자 역할을 정의한 열거형
enum UserRole {
  superAdmin,
  hospitalAdmin,
  doctor,
  nurse,
  staff,
}

/// 인증 상태를 관리하는 Provider 클래스
class AuthProvider with ChangeNotifier {
  // 내부 상태 변수
  bool _isAuthenticated = false;
  String? _currentUser;
  UserRole? _userRole;
  String? _hospitalId;
  String? _hospitalName;

  // 외부에서 접근 가능한 getter
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;
  UserRole? get userRole => _userRole;
  String? get hospitalId => _hospitalId;
  String? get hospitalName => _hospitalName;

  /// 로그인 처리 함수 (Lambda + API Gateway 연동)
  Future<void> login(String email, String password) async {
    final url = Uri.parse(
        'https://hvktzqdl43.execute-api.ap-northeast-2.amazonaws.com/dev/login'); // 실제 로그인 API URL

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 로그인 성공 처리
        _isAuthenticated = true;
        _currentUser = email;

        // 사용자 역할 처리
        final roleString = data['role'] ?? 'staff';
        _userRole = _parseUserRole(roleString);

        // 병원 정보 설정 (선택적)
        _hospitalId = data['hospitalId'] ?? 'H001';
        _hospitalName = data['hospitalName'] ?? '서울대병원';

        notifyListeners();
      } else {
        // 로그인 실패 시 예외 발생
        throw Exception(data['message'] ?? '로그인 실패');
      }
    } catch (e) {
      // 네트워크 오류 또는 기타 예외
      throw Exception('로그인 중 오류 발생: $e');
    }
  }

  /// 회원가입 처리 함수 (Lambda + API Gateway 연동)
  Future<void> signUp(String username, String email, String password) async {
    final url = Uri.parse(
        'https://r1g4copw8j.execute-api.ap-northeast-2.amazonaws.com/dev/signup'); // 실제 회원가입 API URL

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        // 실패 시 예외 발생
        throw Exception(data['message'] ?? '회원가입 실패');
      }

      // 회원가입은 성공했지만 자동 로그인은 하지 않음
      // 필요 시 아래 주석 해제 가능
      /*
      _isAuthenticated = true;
      _currentUser = email;
      _userRole = UserRole.staff;
      _hospitalId = 'H001';
      _hospitalName = '서울대병원';
      notifyListeners();
      */
    } catch (e) {
      // 예외 발생 시 Flutter UI에 전달
      throw Exception('회원가입 중 오류 발생: $e');
    }
  }

  /// 로그아웃 처리
  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    _userRole = null;
    _hospitalId = null;
    _hospitalName = null;
    notifyListeners();
  }

  /// 병원 정보 수동 설정 (예: 슈퍼관리자 병원 선택 시)
  void setHospital(String id, String name) {
    _hospitalId = id;
    _hospitalName = name;
    notifyListeners();
  }

  /// 문자열 역할 값을 UserRole enum으로 변환
  UserRole _parseUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return UserRole.superAdmin;
      case 'hospitaladmin':
        return UserRole.hospitalAdmin;
      case 'doctor':
        return UserRole.doctor;
      case 'nurse':
        return UserRole.nurse;
      default:
        return UserRole.staff;
    }
  }
}
