import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;

/// 회원가입 화면 클래스
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 회원가입 처리 함수
  Future<void> _signUp() async {
    // 1. 입력값 유효성 검사
    if (!_formKey.currentState!.validate()) return;

    // 2. 로딩 상태 시작 및 이전 에러 메시지 초기화
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 3. AuthProvider를 통해 회원가입 API 호출
      await context.read<app_auth.AuthProvider>().signUp(
            _usernameController.text,
            _emailController.text,
            _passwordController.text,
          );
      if (!mounted) return;

      // 4. 성공 시 스낵바 메시지 표시 및 로그인 화면으로 복귀
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입이 완료되었습니다. 로그인 해주세요.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      // 5. 실패 시 에러 메시지 표시
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      // 6. 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따른 반응형 UI를 위한 변수
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          // login_screen과 동일하게 최대 너비 제한
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- UI 요소들은 login_screen의 스타일과 완전히 동일하게 구성 ---
                  Icon(
                    Icons.health_and_safety,
                    size: isSmallScreen ? 80 : 120,
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 28),
                  Text(
                    '회원가입',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  Text(
                    '안전한 환자 관리 시스템을 위한 첫걸음',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // 사용자 이름 입력 필드
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: '사용자 이름',
                      prefixIcon:
                          Icon(Icons.person, color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? '사용자 이름을 입력해주세요' : null,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // 이메일 입력 필드
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      prefixIcon:
                          Icon(Icons.email, color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '이메일을 입력해주세요';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v)) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // 비밀번호 입력 필드 (비밀번호 보기/숨기기 기능 포함)
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
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                      if (v.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                      return null;
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // 비밀번호 확인 입력 필드 (비밀번호 보기/숨기기 기능 포함)
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '비밀번호 확인',
                      prefixIcon:
                          Icon(Icons.lock_outline, color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text)
                        return '비밀번호가 일치하지 않습니다';
                      return null;
                    },
                  ),

                  // 서버로부터 받은 에러 메시지 표시
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // 회원가입 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
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
                        : Text('회원가입',
                            style:
                                TextStyle(fontSize: isSmallScreen ? 16 : 18)),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // 로그인 화면으로 돌아가기 버튼
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade700),
                    child: Text('이미 계정이 있으신가요? 로그인',
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
