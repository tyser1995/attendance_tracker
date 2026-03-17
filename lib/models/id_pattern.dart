class IdPattern {
  final String id;
  final String pattern; // e.g. ##-E###-##
  final String regex;   // e.g. ^\d{2}-E\d{3}-\d{2}$
  final String status;  // 'active' | 'inactive'
  final String? createdAt;
  final String? updatedAt;

  const IdPattern({
    required this.id,
    required this.pattern,
    required this.regex,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';

  bool validate(String idNumber) {
    if (!isActive) return false;
    return RegExp(regex).hasMatch(idNumber);
  }

  factory IdPattern.fromMap(Map<String, dynamic> map) {
    return IdPattern(
      id: map['id']?.toString() ?? '',
      pattern: map['pattern'] ?? '',
      regex: map['regex'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pattern': pattern,
      'regex': regex,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convert pattern like ##-E###-## to regex ^\d{2}-E\d{3}-\d{2}$
  static String buildRegex(String pattern) {
    final buf = StringBuffer('^');
    for (int i = 0; i < pattern.length; i++) {
      final ch = pattern[i];
      if (ch == '#') {
        buf.write(r'\d');
      } else if (RegExp(r'[A-Za-z0-9]').hasMatch(ch)) {
        buf.write(ch);
      } else {
        // Escape special regex chars
        buf.write(RegExp.escape(ch));
      }
    }
    buf.write(r'$');
    return buf.toString();
  }
}
