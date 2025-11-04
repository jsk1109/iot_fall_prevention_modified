import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iot_fall_prevention/services/api_service.dart'; // baseUrl 참조용

enum UserRole {
  admin,
  staff,
  unknown, // 역할 파싱 실패 시
}

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUserId;
  UserRole _userRole = UserRole.unknown;
  String? _nursingHomeName; // 이름 필드는 서버 응답에 없으므로 사용 보류
  String? _accessToken;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  UserRole get userRole => _userRole;
  String? get nursingHomeName => _nursingHomeName;
  String? get accessToken => _accessToken;

  Future<void> login(String userId, String password) async {
    final url = Uri.parse('${ApiService.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final String token = data['access_token'];

        final parts = token.split('-');
        if (parts.length < 4) {
          throw Exception('수신된 토큰 형식이 잘못되었습니다.');
        }

        final String parsedUserId = parts[2];
        final String parsedRole = parts[3];

        _isAuthenticated = true;
        _currentUserId = parsedUserId;
        _userRole = _parseUserRole(parsedRole);
        _accessToken = token;

        _nursingHomeName = parsedUserId;

        notifyListeners();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? '로그인 실패');
      }
    } catch (e) {
      throw Exception('로그인 중 오류 발생: $e');
    }
  }

  Future<void> signUp(String username, String email, String password) async {
    final url = Uri.parse('${ApiService.baseUrl}/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': username,
          'name': username, // name 필드는 user_id와 동일하게 설정
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 201) {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? '회원가입 실패');
      }
    } catch (e) {
      throw Exception('회원가입 중 오류 발생: $e');
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUserId = null;
    _userRole = UserRole.unknown;
    _nursingHomeName = null;
    _accessToken = null;
    notifyListeners();
  }

  UserRole _parseUserRole(String role) {
    return role.toLowerCase() == 'admin' ? UserRole.admin : UserRole.staff;
  }
}
