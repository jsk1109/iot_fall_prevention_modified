// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iot_fall_prevention/models/patient_model.dart';
import 'package:iot_fall_prevention/models/user_model.dart';
import 'package:iot_fall_prevention/models/ultrasonic_data.dart' as model;

class ApiService {
  static const String baseUrl = 'http://121.78.128.175';

  // --- 1. 인증 API (최종 경로 반영) ---
  static Future<Map<String, dynamic>> login(
      String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'), // '/auth' 접두사 추가
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'user_id': userId, 'password': password}),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final responseBody = response.bodyBytes.isNotEmpty
          ? utf8.decode(response.bodyBytes)
          : '{}';
      final errorBody = json.decode(responseBody);
      throw Exception(
          '로그인 실패: ${errorBody['detail'] ?? response.reasonPhrase ?? 'Unknown error'}');
    }
  }

  // --- 2. Staff 화면 API (최종 경로 반영) ---
  static Future<List<Patient>> getAllPatients() async {
    final response = await http.get(Uri.parse('$baseUrl/patients'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => Patient.fromJson(item)).toList();
    } else {
      throw Exception('환자 목록을 불러오는 데 실패했습니다.');
    }
  }

  static Future<List<model.UltrasonicU4Response>> getUltrasonicHistory(
      String bedId,
      {int limit = 100,
      int durationMinutes = 0}) async {
    String url = '$baseUrl/events/ultrasonic/$bedId/history?limit=$limit';
    if (durationMinutes > 0) {
      url += '&duration_minutes=$durationMinutes';
    }
    final Uri uri = Uri.parse(url);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        // [수정] List<model.UltrasonicU4Response>로 직접 파싱
        return data
            .map((item) => model.UltrasonicU4Response.fromJson(
                item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404 || response.body.isEmpty) {
        return [];
      } else {
        throw Exception(
            'Failed to load ultrasonic history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load ultrasonic history: $e');
    }
  }

  // --- 4. Admin API (최종 경로 반영 및 인자 수정) ---
  // [수정] adminId 인자 제거
  static Future<List<User>> getAllUsers() async {
    // [수정] API 경로를 /users로 복원
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('사용자 목록을 불러오는 데 실패했습니다.');
    }
  }

  // [수정] adminId 인자 제거
  static Future<bool> updateUserRole(
      String targetUserId, String newRole) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$targetUserId/role'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      // [수정] admin_id를 body에서 제거
      body: json.encode({'new_role': newRole}),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('사용자 역할 변경에 실패했습니다: ${response.statusCode}');
    }
  }

  // 낙상 시뮬레이션 (유지)
  static Future<void> simulateFallEvent(String roomId, String bedId) async {
    // (이 API는 현재 서버에 정의되지 않았을 수 있으나, 코드는 유지합니다)
    final response = await http.post(
      Uri.parse('$baseUrl/events/simulate/fall'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'nursinghome_id': 'NH-001',
        'room_id': roomId,
        'bed_id': bedId,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to simulate fall event.');
    }
  }
}
