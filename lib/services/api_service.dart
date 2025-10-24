import 'dart:convert';
import 'package:http/http.dart' as http;

// --- 필요한 모델 Import ---
import '../models/patient_model.dart';
import '../models/sensor_data.dart';
import '../models/user_model.dart';
import '../models/ultrasonic_data.dart';

class ApiService {
  // --- 서버 주소 ---
  static const String baseUrl = 'http://121.78.128.175'; // http:// 포함 확인

  // --- 인증 관련 API ---
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
      final responseBody = response.bodyBytes.isNotEmpty
          ? utf8.decode(response.bodyBytes)
          : '{}';
      final errorBody = json.decode(responseBody);
      throw Exception(
          '로그인 실패: ${errorBody['detail'] ?? response.reasonPhrase ?? 'Unknown error'}');
    }
  }

  // --- Staff 화면용 API ---
  static Future<List<Patient>> getAllPatients(String nursinghomeId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/patients/$nursinghomeId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => Patient.fromJson(item)).toList();
    } else {
      throw Exception('환자 목록을 불러오는 데 실패했습니다.');
    }
  }

  static Future<SensorData> getMostRecentEventForPatient(
      String roomId, String bedId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/events/patient/$roomId/$bedId/most-recent'));
    if (response.statusCode == 200) {
      final dynamic data = json.decode(utf8.decode(response.bodyBytes));
      return SensorData.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('No events found for this patient');
    } else {
      throw Exception('환자의 마지막 이벤트를 불러오는 데 실패했습니다.');
    }
  }

  // --- Bed Monitor 화면용 API ---
  // [수정] durationMinutes 파라미터 정의 추가 (int 타입, 기본값 0)
  static Future<Map<String, List<UltrasonicData>>> getUltrasonicHistory(
      String bedId,
      {int limit = 1000,
      int durationMinutes = 0}) async {
    String url = '$baseUrl/ultrasonic/$bedId/history?limit=$limit';
    if (durationMinutes > 0) {
      url += '&duration_minutes=$durationMinutes';
    }

    final Uri uri = Uri.parse(url);
    print('Requesting Ultrasonic History from: $uri');

    try {
      final response = await http.get(uri);
      print('Ultrasonic History Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded =
            json.decode(utf8.decode(response.bodyBytes));
        if (decoded.containsKey('data') && decoded['data'] is Map) {
          final Map<String, dynamic> dataMap = decoded['data'];
          final Map<String, List<UltrasonicData>> result = {};
          dataMap.forEach((sensorId, dataList) {
            if (dataList is List) {
              result[sensorId] = dataList
                  .map((item) =>
                      UltrasonicData.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          });
          print('Successfully parsed ${result.length} sensors data.');
          return result;
        } else {
          print('Error: Invalid response format from server.');
          throw Exception('Invalid response format from server.');
        }
      } else if (response.statusCode == 404) {
        print('No ultrasonic data found for bed: $bedId');
        return {};
      } else {
        print(
            'Error loading ultrasonic history: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to load ultrasonic history: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception caught in getUltrasonicHistory: $e');
      throw Exception('Failed to load ultrasonic history: $e');
    }
  }

  // --- Admin 화면용 API ---
  static Future<List<User>> getAllUsers(String adminId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$adminId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('사용자 목록을 불러오는 데 실패했습니다.');
    }
  }

  static Future<bool> updateUserRole(
      String targetUserId, String newRole, String adminId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$targetUserId/role'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'admin_id': adminId, 'new_role': newRole}),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print(
          'Failed to update user role: ${response.statusCode} ${response.body}');
      throw Exception('사용자 역할 변경에 실패했습니다: ${response.statusCode}');
    }
  }

  // 낙상 시뮬레이션 함수
  static Future<void> simulateFallEvent(String roomId, String bedId) async {
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
