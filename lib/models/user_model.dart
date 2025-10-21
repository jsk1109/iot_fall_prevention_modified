class User {
  // FastAPI가 보내주는 데이터 key와 정확히 일치하는 속성들
  final String nursinghomeId;
  final String nursinghomeName;
  final String email;
  final String role;

  User({
    required this.nursinghomeId,
    required this.nursinghomeName,
    required this.email,
    required this.role,
  });

  // 서버에서 받은 JSON을 User 객체로 변환하는 부분
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nursinghomeId: json['nursinghome_id'],
      nursinghomeName: json['nursinghome_name'],
      email: json['email'],
      role: json['role'],
    );
  }
}
