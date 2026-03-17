class Course {
  final String id;
  final String courseCode;
  final String courseName;
  final String yearLevel;
  final String? createdAt;
  final String? updatedAt;

  const Course({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.yearLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id']?.toString() ?? '',
      courseCode: map['course_code'] ?? '',
      courseName: map['course_name'] ?? '',
      yearLevel: map['year_level']?.toString() ?? '',
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_code': courseCode,
      'course_name': courseName,
      'year_level': yearLevel,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Course copyWith({
    String? id,
    String? courseCode,
    String? courseName,
    String? yearLevel,
  }) {
    return Course(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      yearLevel: yearLevel ?? this.yearLevel,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
