import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ApiService를 직접 사용합니다.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- 기존 UI 상태 변수 + 신규 로직 변수 ---
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(); // email에서 id로 변경
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 새로운 로그인 로직 ---
  Future<void> _login() async {
    // 1. 유효성 검사 (기존 코드 유지)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. ApiService를 직접 호출하여 로그인 시도
      final data =
          await ApiService.login(_idController.text, _passwordController.text);
      if (!mounted) return;

      final role = data['role'];
      final userId = data['user_id'];

      // 3. 역할(role)에 따라 다른 화면으로 이동
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin', arguments: userId);
      } else if (role == 'staff') {
        Navigator.pushReplacementNamed(context, '/staff', arguments: userId);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('권한이 없는 사용자입니다.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: ${e.toString()}'),
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
    // --- 기존 UI 부분 (일부만 수정) ---
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
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 28),
                  Text(
                    'IoT 스마트 낙상 예방 시스템',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  Text(
                    '안전한 환자 관리의 시작',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 48 : 64),
                  // [변경점] '이메일' -> '아이디'
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: '아이디', // <-- UI 텍스트 변경
                      prefixIcon:
                          Icon(Icons.person, color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '아이디를 입력해주세요';
                      }
                      return null;
                    },
                    cursorColor: Colors.blue,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                    cursorColor: Colors.blue,
                  ),
                  SizedBox(height: isSmallScreen ? 32 : 48),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 18),
                    ),
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
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade700),
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
