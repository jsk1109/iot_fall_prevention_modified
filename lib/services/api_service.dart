// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/patient_model.dart';
import '../models/sensor_data.dart';
import '../models/user_model.dart';

class ApiService {
  // [수정 1] 서버 포트(:8000)를 반드시 포함해야 합니다.
  static const String baseUrl = 'http://121.78.128.175';

  // --- 인증 관련 API ---

  // 로그인 (한글 깨짐 방지를 위해 utf8 디코딩 적용)
  static Future<Map<String, dynamic>> login(
      String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'user_id': userId, 'password': password}),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = json.decode(utf8.decode(response.bodyBytes));
      throw Exception('로그인 실패: ${errorBody['detail']}');
    }
  }

  // 회원가입
  static Future<bool> register(
      String userId, String password, String name, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'user_id': userId,
        'password': password,
        'name': name,
        'email': email
      }),
    );
    return response.statusCode == 201;
  }

  // --- Staff (직원) 화면용 API ---

  // 모든 환자 목록 가져오기
  static Future<List<Patient>> getAllPatients(String nursinghomeId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/patients/$nursinghomeId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => Patient.fromJson(item)).toList();
    }
    throw Exception('환자 목록을 불러오는 데 실패했습니다.');
  }

  // [수정 2] staff_screen.dart가 사용할 가장 중요한 함수입니다.
  // 특정 환자 한 명의 가장 마지막 이벤트를 가져오는 함수
  static Future<SensorData> getMostRecentEventForPatient(
      String roomId, String bedId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/events/patient/$roomId/$bedId/most-recent'));

    if (response.statusCode == 200) {
      final dynamic data = json.decode(utf8.decode(response.bodyBytes));
      return SensorData.fromJson(data);
    } else if (response.statusCode == 404) {
      // 404는 에러가 아니라 '이벤트 없음'을 의미하므로, 구체적인 예외를 던져 UI에서 처리하게 합니다.
      throw Exception('No events found for this patient');
    } else {
      throw Exception('환자의 마지막 이벤트를 불러오는 데 실패했습니다.');
    }
  }

  // --- Admin (관리자) 화면용 API ---

  // 모든 사용자(직원/관리자) 목록 조회
  static Future<List<User>> getAllUsers(String adminId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$adminId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => User.fromJson(item)).toList();
    }
    throw Exception('사용자 목록을 불러오는 데 실패했습니다.');
  }

  // 사용자 역할 변경
  static Future<bool> updateUserRole(
      String targetUserId, String newRole, String adminId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$targetUserId/role'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'admin_id': adminId, 'new_role': newRole}),
    );
    return response.statusCode == 200;
  }
}
