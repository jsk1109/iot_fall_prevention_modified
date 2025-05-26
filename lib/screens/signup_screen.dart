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
  // 폼 유효성 검사용 키
  final _formKey = GlobalKey<FormState>();

  // 입력 컨트롤러 (사용자 이름, 이메일, 비밀번호, 비밀번호 확인)
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 로딩 상태 및 에러 메시지
  bool _isLoading = false;
  String? _errorMessage;

  /// 회원가입 처리 함수
  Future<void> _signUp() async {
    // 입력값 유효성 검사
    if (!_formKey.currentState!.validate()) return;

    // 로딩 시작
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // AuthProvider의 signUp 메서드 호출 (Lambda API 호출)
      await context.read<app_auth.AuthProvider>().signUp(
            _usernameController.text,
            _emailController.text,
            _passwordController.text,
          );

      // 성공 시 안내 메시지 출력 및 로그인 화면으로 이동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입이 완료되었습니다. 로그인 해주세요.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // 실패 시 에러 메시지 표시
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      // 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 컨트롤러 해제
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Container(
        // 배경 그라데이션 설정
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 32.0 : size.width * 0.1,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey, // 폼 유효성 체크에 사용
                child: Column(
                  children: [
                    // 상단 로고 아이콘
                    Icon(Icons.health_and_safety,
                        size: 100, color: Colors.blue.shade700),
                    const SizedBox(height: 16),

                    // 화면 제목
                    Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 서브 텍스트
                    Text(
                      'IoT 스마트 낙상 예방 시스템에 오신 것을 환영합니다',
                      style:
                          TextStyle(fontSize: 16, color: Colors.blue.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 사용자 이름 입력 필드
                    _buildTextField(
                      '사용자 이름',
                      _usernameController,
                      Icons.person,
                      validator: (v) => v!.isEmpty ? '사용자 이름을 입력해주세요' : null,
                    ),
                    const SizedBox(height: 16),

                    // 이메일 입력 필드
                    _buildTextField(
                      '이메일',
                      _emailController,
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return '이메일을 입력해주세요';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return '올바른 이메일 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 입력 필드
                    _buildTextField(
                      '비밀번호',
                      _passwordController,
                      Icons.lock,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                        if (v.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 확인 입력 필드
                    _buildTextField(
                      '비밀번호 확인',
                      _confirmPasswordController,
                      Icons.lock_outline,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return '비밀번호를 다시 입력해주세요';
                        if (v != _passwordController.text)
                          return '비밀번호가 일치하지 않습니다';
                        return null;
                      },
                    ),

                    // 에러 메시지 출력
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ],

                    const SizedBox(height: 32),

                    // 회원가입 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('회원가입',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 로그인 화면으로 돌아가기
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '이미 계정이 있으신가요? 로그인',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 입력 필드 빌더 위젯
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText, // 비밀번호 등 숨김 여부
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700),
        ),
      ),
    );
  }
}
