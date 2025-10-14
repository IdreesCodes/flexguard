class AppUser {
  final int? id;
  final String username;
  final String passwordHash; // SHA-256 hash
  final int createdAt; // epoch millis

  const AppUser({this.id, required this.username, required this.passwordHash, required this.createdAt});

  AppUser copyWith({int? id, String? username, String? passwordHash, int? createdAt}) => AppUser(
        id: id ?? this.id,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'username': username,
        'password_hash': passwordHash,
        'created_at': createdAt,
      };

  static AppUser fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as int?,
        username: map['username'] as String,
        passwordHash: map['password_hash'] as String,
        createdAt: map['created_at'] as int,
      );
}


