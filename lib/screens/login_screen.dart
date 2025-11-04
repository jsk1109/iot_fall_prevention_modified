import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 1. ApiService 대신 AuthProvider를 import합니다.
import 'package:iot_fall_prevention/providers/auth_provider.dart' as auth_p;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 2. AuthProvider를 사용하는 로그인 로직 ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. context.read를 사용하여 AuthProvider의 login 메서드 호출
      await context.read<auth_p.AuthProvider>().login(
            _idController.text,
            _passwordController.text,
          );

      if (!mounted) return;

      // 4. 로그인 성공 후 Provider에서 역할(role)을 가져옵니다.
      final authProvider = context.read<auth_p.AuthProvider>();
      final role = authProvider.userRole;
      final userId = authProvider.currentUserId;

      if (role == auth_p.UserRole.admin) {
        Navigator.pushReplacementNamed(context, '/admin', arguments: userId);
      } else if (role == auth_p.UserRole.staff) {
        Navigator.pushReplacementNamed(context, '/staff', arguments: userId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알 수 없는 사용자 역할입니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceAll('Exception: ', '')), // 에러 메시지 정리
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: isSmallScreen ? 80 : 120,
                    color: Colors.indigo.shade700, // 테마 색상과 일치
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 28),
                  Text(
                    'IoT 스마트 낙상 예방 시스템',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900, // 테마 색상과 일치
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  Text(
                    '안전한 환자 관리의 시작',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      color: Colors.indigo.shade700, // 테마 색상과 일치
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 48 : 64),
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: '아이디',
                      prefixIcon: Icon(Icons.person,
                          color: Colors.indigo.shade700), // 테마 색상
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '아이디를 입력해주세요';
                      }
                      return null;
                    },
                    cursorColor: Colors.indigo, // 테마 색상
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon:
                          Icon(Icons.lock, color: Colors.indigo.shade700),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _login(),
                    cursorColor: Colors.indigo,
                  ),
                  SizedBox(height: isSmallScreen ? 32 : 48),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('로그인',
                            style:
                                TextStyle(fontSize: isSmallScreen ? 16 : 18)),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: Text('계정이 없으신가요? 회원가입',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
