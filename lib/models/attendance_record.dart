/// status: 1 = AM Time In, 2 = AM Time Out, 3 = PM Time In, 4 = PM Time Out
class AttendanceRecord {
  final String id;
  final String idNumber;
  final String name;
  final String? timeIn;   // HH:mm:ss
  final String? timeOut;  // HH:mm:ss
  final String createdDate; // YYYY-MM-DD
  final int status;
  final String? createdAt;
  final String? updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.idNumber,
    required this.name,
    this.timeIn,
    this.timeOut,
    required this.createdDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case 1: return 'AM Time In';
      case 2: return 'AM Time Out';
      case 3: return 'PM Time In';
      case 4: return 'PM Time Out';
      default: return 'Unknown';
    }
  }

  bool get isTimeIn => status == 1 || status == 3;

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id']?.toString() ?? '',
      idNumber: map['idnumber'] ?? '',
      name: map['name'] ?? '',
      timeIn: map['time_in'],
      timeOut: map['time_out'],
      createdDate: map['created_date'] ?? '',
      status: map['status'] is int ? map['status'] : int.tryParse(map['status'].toString()) ?? 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idnumber': idNumber,
      'name': name,
      'time_in': timeIn,
      'time_out': timeOut,
      'created_date': createdDate,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

/// Represents a student's full day attendance summary
class DayAttendance {
  final String idNumber;
  final String name;
  final String date;
  final String? amTimeIn;
  final String? amTimeOut;
  final String? pmTimeIn;
  final String? pmTimeOut;

  const DayAttendance({
    required this.idNumber,
    required this.name,
    required this.date,
    this.amTimeIn,
    this.amTimeOut,
    this.pmTimeIn,
    this.pmTimeOut,
  });

  bool get isPresent => amTimeIn != null || pmTimeIn != null;
  int get logsCount {
    int c = 0;
    if (amTimeIn != null) c++;
    if (amTimeOut != null) c++;
    if (pmTimeIn != null) c++;
    if (pmTimeOut != null) c++;
    return c;
  }
}
