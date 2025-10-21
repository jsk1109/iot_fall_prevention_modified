import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 이제 아래 코드는 모두 정상적으로 작동합니다.
enum UserRole {
  admin,
  staff,
}

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUserId;
  UserRole? _userRole;
  String? _nursingHomeName;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  UserRole? get userRole => _userRole;
  String? get nursingHomeName => _nursingHomeName;

  Future<void> login(String userId, String password) async {
    final url = Uri.parse('http://121.78.128.175/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _isAuthenticated = true;
        _currentUserId = data['user_id'];
        _nursingHomeName = data['name'];
        _userRole = _parseUserRole(data['role']);
        notifyListeners(); // 이제 에러가 발생하지 않습니다.
      } else {
        throw Exception(data['detail'] ?? '로그인 실패');
      }
    } catch (e) {
      throw Exception('로그인 중 오류 발생: $e');
    }
  }

  Future<void> signUp(String username, String email, String password) async {
    final url = Uri.parse('http://121.78.128.175/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': username,
          'name': username,
          'email': email,
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 201) {
        throw Exception(data['detail'] ?? '회원가입 실패');
      }
    } catch (e) {
      throw Exception('회원가입 중 오류 발생: $e');
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUserId = null;
    _userRole = null;
    _nursingHomeName = null;
    notifyListeners(); // 이제 에러가 발생하지 않습니다.
  }

  UserRole _parseUserRole(String role) {
    return role.toLowerCase() == 'admin' ? UserRole.admin : UserRole.staff;
  }
}
