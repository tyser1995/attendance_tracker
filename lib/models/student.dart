class Student {
  final String id;
  final String idNumber;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? dateOfBirth; // ISO date string
  final String? sex; // 'M' or 'F'
  final String? courseId;
  final bool isDeleted;
  final String? createdAt;
  final String? updatedAt;

  // joined
  final String? courseName;
  final String? courseCode;

  const Student({
    required this.id,
    required this.idNumber,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.dateOfBirth,
    this.sex,
    this.courseId,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.courseName,
    this.courseCode,
  });

  String get fullName {
    final parts = [firstName];
    if (middleName != null && middleName!.isNotEmpty) parts.add(middleName!);
    parts.add(lastName);
    return parts.join(' ');
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id']?.toString() ?? '',
      idNumber: map['idnumber'] ?? '',
      firstName: map['fn'] ?? '',
      lastName: map['ln'] ?? '',
      middleName: map['mn'],
      dateOfBirth: map['dob'],
      sex: map['sex'],
      courseId: map['course_id']?.toString(),
      isDeleted: (map['is_deleted'] ?? 0) == 1 || map['is_deleted'] == true,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      courseName: map['course_name'],
      courseCode: map['course_code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idnumber': idNumber,
      'fn': firstName,
      'ln': lastName,
      'mn': middleName,
      'dob': dateOfBirth,
      'sex': sex,
      'course_id': courseId,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Student copyWith({
    String? id,
    String? idNumber,
    String? firstName,
    String? lastName,
    String? middleName,
    String? dateOfBirth,
    String? sex,
    String? courseId,
    bool? isDeleted,
    String? courseName,
    String? courseCode,
  }) {
    return Student(
      id: id ?? this.id,
      idNumber: idNumber ?? this.idNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      courseId: courseId ?? this.courseId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
    );
  }
}
