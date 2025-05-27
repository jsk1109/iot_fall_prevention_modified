import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'hospital_selection_screen.dart';

// 로그인 화면
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.login(
          _emailController.text,
          _passwordController.text,
        );

        if (!mounted) return;

        // 사용자 역할에 따라 다른 화면으로 이동
        if (authProvider.userRole == UserRole.superAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HospitalSelectionScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
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
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;

    return Scaffold(
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Scrollbar(
          thickness: 6,
          radius: const Radius.circular(8),
          thumbVisibility: false,
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 280,
                  maxWidth: isSmallScreen ? double.infinity : 400,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로고
                      Icon(
                        Icons.health_and_safety,
                        size: isSmallScreen ? 80 : 120,
                        color: Colors.blue.shade700,
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      // 제목
                      Text(
                        'IoT 스마트 낙상 예방 시스템',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 16),
                      Text(
                        '안전한 환자 관리의 시작',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          color: Colors.blue.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 48 : 64),
                      // 입력 필드 컨테이너
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen ? double.infinity : 400,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                        child: Column(
                          children: [
                            // 이메일 입력
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: '이메일',
                                labelStyle:
                                    TextStyle(color: Colors.blue.shade700),
                                prefixIcon: Icon(Icons.email,
                                    color: Colors.blue.shade700),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade700),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '이메일을 입력해주세요';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return '올바른 이메일 형식이 아닙니다';
                                }
                                return null;
                              },
                              cursorColor: Colors.blue,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            // 비밀번호 입력
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                labelStyle:
                                    TextStyle(color: Colors.blue.shade700),
                                prefixIcon: Icon(Icons.lock,
                                    color: Colors.blue.shade700),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade700),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
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
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 48),
                      // 로그인 버튼
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: isSmallScreen ? double.infinity : 400,
                        ),
                        height: isSmallScreen ? 50 : 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: isSmallScreen ? 24 : 32,
                                  height: isSmallScreen ? 24 : 32,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  '로그인',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // 회원가입 버튼
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                        ),
                        child: Text(
                          '계정이 없으신가요? 회원가입',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                      // 로그인 폼 아래쪽에
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/sensor'),
                        child: const Text('센서 모니터링 보기'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
