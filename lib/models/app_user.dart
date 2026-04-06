class AppUser {
  final String id;
  final String username;
  final String passwordHash;
  final String role; // 'super_admin' | 'admin' | 'staff'

  /// Shared ID used by RFID (keyboard HID input) and Barcode (camera scan).
  final String? cardId;

  /// JSON-encoded list of 128 floats from face-api.js face descriptor.
  final String? faceDescriptor;

  const AppUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.cardId,
    this.faceDescriptor,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get hasFaceEnrolled => faceDescriptor != null;
  bool get hasCardEnrolled => cardId != null && cardId!.isNotEmpty;

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        username: m['username'] as String,
        passwordHash: m['password_hash'] as String,
        role: m['role'] as String? ?? 'staff',
        cardId: m['card_id'] as String?,
        faceDescriptor: m['face_descriptor'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password_hash': passwordHash,
        'role': role,
        'card_id': cardId,
        'face_descriptor': faceDescriptor,
      };
}
