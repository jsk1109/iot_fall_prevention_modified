import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // FCM 권한 요청
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // FCM 토큰 가져오기
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // 포그라운드 메시지 핸들러
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('포그라운드 메시지 수신: ${message.notification?.title}');
        // TODO: 알림 표시 로직 구현
      });

      // 백그라운드 메시지 핸들러
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    }
  }
}

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('백그라운드 메시지 수신: ${message.notification?.title}');
  // TODO: 백그라운드 알림 처리 로직 구현
}
