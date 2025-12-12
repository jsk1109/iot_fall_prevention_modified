import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iot_fall_prevention/models/patient_model.dart';
import 'package:iot_fall_prevention/models/user_model.dart';
import 'package:iot_fall_prevention/models/ultrasonic_data.dart' as model;
import 'package:iot_fall_prevention/models/sensor_data_model.dart';

class ApiService {
  static const String baseUrl = 'http://121.78.128.175:8000';

  static Future<Map<String, dynamic>> login(
      String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
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
          '로그인 실패: ${errorBody['detail'] ?? response.reasonPhrase}');
    }
  }

  static Future<List<Patient>> getAllPatients() async {
    final response = await http.get(Uri.parse('$baseUrl/patients'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => Patient.fromJson(item)).toList();
    } else {
      throw Exception('환자 목록 로드 실패');
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
        return data
            .map((item) => model.UltrasonicU4Response.fromJson(
                item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404 || response.body.isEmpty) {
        return [];
      } else {
        throw Exception('이력 로드 실패');
      }
    } catch (e) {
      throw Exception('이력 로드 실패: $e');
    }
  }

  static Future<List<User>> getAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('사용자 목록 로드 실패');
    }
  }

  static Future<bool> updateUserRole(
      String targetUserId, String newRole) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$targetUserId/role'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'new_role': newRole}),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('역할 변경 실패');
    }
  }

  static Future<void> updateFcmToken(String userId, String token) async {
    final url = Uri.parse('$baseUrl/users/$userId/fcm-token');
    try {
      await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      print("FCM 토큰 전송 에러: $e");
    }
  }

  static Future<List<SensorDataModel>> getStaffLogs(
      String nursingHomeId) async {
    final uri = Uri.parse(
        '$baseUrl/events/staff/logs?nursinghome_id=$nursingHomeId&limit=50');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => SensorDataModel.fromJson(item)).toList();
    } else {
      throw Exception('로그 로드 실패');
    }
  }
}
