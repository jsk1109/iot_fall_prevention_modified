// lib/screens/sensor_monitor.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// 센서 데이터 모델
class SensorData {
  final String entityKey;
  final String timestamp;
  final int call;
  final int fall;
  final int ultraSonic;

  SensorData({
    required this.entityKey,
    required this.timestamp,
    required this.call,
    required this.fall,
    required this.ultraSonic,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final v = json['value'] as Map<String, dynamic>;
    return SensorData(
      entityKey: json['entityKey'] as String,
      timestamp: json['timestamp'] as String,
      call: v['call'] as int,
      fall: v['fall'] as int,
      ultraSonic: v['ultraSonic'] as int,
    );
  }
}

class SensorMonitorScreen extends StatefulWidget {
  const SensorMonitorScreen({Key? key}) : super(key: key);

  @override
  _SensorMonitorScreenState createState() => _SensorMonitorScreenState();
}

class _SensorMonitorScreenState extends State<SensorMonitorScreen> {
  // 실제 배포된 API 엔드포인트
  static const _apiUrl =
      'https://hkf0mt14ca.execute-api.ap-northeast-2.amazonaws.com/dev/devicedata';

  bool _loading = true;
  String? _error;
  List<SensorData> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final resp = await http.get(Uri.parse(_apiUrl));
      if (resp.statusCode == 200) {
        // {"items":[{...},{...},...]} 형태라면
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = body['items'] as List<dynamic>;
        setState(() {
          _items = list
              .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = '응답 오류: ${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '데이터 로드 실패: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Monitor')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final d = _items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(d.entityKey),
                        subtitle: Text(
                          'Time: ${d.timestamp}\n'
                          'Call: ${d.call}, Fall: ${d.fall}, Ultra: ${d.ultraSonic}',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
