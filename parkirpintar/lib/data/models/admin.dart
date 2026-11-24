class Admin {
  const Admin({
    required this.id,
    required this.nama,
    required this.aktif,
    this.username,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: (json['id'] as num).toInt(),
      nama: json['nama'] as String,
      username: json['username'] as String?,
      aktif: json['aktif'] as bool,
    );
  }

  final int id;
  final String nama;
  final String? username;
  final bool aktif;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    if (username != null) 'username': username,
    'aktif': aktif,
  };
}

class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.tokenType,
    required this.admin,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      admin: Admin.fromJson(json['admin'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final String tokenType;
  final Admin admin;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
    'admin': admin.toJson(),
  };
}
