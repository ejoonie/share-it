class UserModel {
  final int id;
  final String email;
  final String nickName;
  final bool isGuest;
  final String token;
  final String? termsAcceptedAt;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.nickName,
    required this.isGuest,
    required this.token,
    this.termsAcceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasAcceptedTerms => termsAcceptedAt != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      nickName: json['nick_name'] as String,
      isGuest: json['is_guest'] as bool,
      token: json['token'] as String,
      termsAcceptedAt: json['terms_accepted_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
