import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/staff_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 웹에서는 백그라운드 처리를 생략 (에러 방지)
  if (kIsWeb) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Firebase.apps.isEmpty 체크를 제거하고 바로 초기화 시도
      // (JS SDK 미로드 시 isEmpty 체크 자체가 에러를 낼 수 있음)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase Initialized");
    } catch (e) {
      // 이미 초기화되었거나, 초기화 실패 시 로그만 남기고 앱은 계속 실행
      debugPrint("Firebase Init Warning (Ignored): $e");
    }
    // --- 수정된 부분 끝 ---

    // 웹이 아닐 때만 메시징 설정
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // 에러 화면 표시
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.redAccent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              const Text("CRITICAL ERROR",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(error.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    ));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT 모니터링',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/admin') {
          final adminId = (settings.arguments as String?) ?? '';
          return MaterialPageRoute(
            builder: (_) => AdminScreen(adminId: adminId),
          );
        }
        if (settings.name == '/staff') {
          final staffId = (settings.arguments as String?) ?? '';
          return MaterialPageRoute(
            builder: (_) => StaffScreen(staffId: staffId),
          );
        }
        return null;
      },
    );
  }
}
