import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
// import 'services/fcm_service.dart';

// Flutter 애플리케이션의 진입점
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화 (주석 처리됨)
  // await Firebase.initializeApp();

  // FCM 서비스 초기화 (주석 처리됨)
  // final fcmService = FCMService();
  // await fcmService.initialize();

  runApp(const MyApp());
}

// 애플리케이션의 루트 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 인증 관련 상태 관리
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // 환자 정보 관련 상태 관리
        ChangeNotifierProvider(create: (_) => PatientProvider()),
      ],
      child: MaterialApp(
        title: 'IoT 낙상 예방 시스템',
        theme: ThemeData(
          primaryColor: Colors.white,
          brightness: Brightness.light,
          fontFamily: 'NotoSans',
          textTheme: const TextTheme(
            displayLarge: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
            titleLarge: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w500,
                color: Colors.black54),
            bodyMedium: TextStyle(fontSize: 16.0, color: Colors.black87),
          ),
          buttonTheme: ButtonThemeData(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            buttonColor: Colors.lightBlueAccent,
            textTheme: ButtonTextTheme.primary,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.lightBlueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.lightBlueAccent,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              shadows: [
                Shadow(
                  blurRadius: 5.0,
                  color: Colors.black26,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
            iconTheme: IconThemeData(color: Colors.black87),
          ),
          colorScheme: const ColorScheme.light(
            primary: Colors.white,
            secondary: Colors.lightBlueAccent,
          ).copyWith(secondary: Colors.lightBlueAccent),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueGrey,
          fontFamily: 'NotoSans',
          textTheme: const TextTheme(
            displayLarge: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.w600,
                color: Colors.white),
            titleLarge: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w500,
                color: Colors.white70),
            bodyMedium: TextStyle(fontSize: 16.0, color: Colors.white70),
          ),
          buttonTheme: ButtonThemeData(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            buttonColor: Colors.blueGrey,
            textTheme: ButtonTextTheme.primary,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueGrey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.lightBlueAccent,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blueGrey,
            titleTextStyle: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueGrey,
            secondary: Colors.lightBlueAccent,
          ).copyWith(secondary: Colors.lightBlueAccent),
        ),
        themeMode: ThemeMode.system, // 시스템 설정에 따라 테마 변경
        initialRoute: '/login',
        routes: {
          // 로그인 화면
          '/login': (context) => const LoginScreen(),
          // 회원가입 화면
          '/signup': (context) => const SignUpScreen(),
          // 홈 화면
          '/home': (context) => const HomeScreen(),
          // 관리자 화면
          '/admin': (context) => const AdminScreen(),
        },
      ),
    );
  }
}
