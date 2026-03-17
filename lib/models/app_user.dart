class AppUser {
  final String id;
  final String username;
  final String passwordHash;
  final String role; // 'super_admin' | 'admin' | 'staff'

  const AppUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        username: m['username'] as String,
        passwordHash: m['password_hash'] as String,
        role: m['role'] as String? ?? 'staff',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password_hash': passwordHash,
        'role': role,
      };
}
