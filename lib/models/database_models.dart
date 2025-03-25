class Student {
  final String? id;
  final String name;
  final String rollNumber;
  final String classId;
  final String? faceData;

  Student({
    this.id,
    required this.name,
    required this.rollNumber,
    required this.classId,
    this.faceData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'roll_number': rollNumber,
      'class_id': classId,
      'face_data': faceData,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      rollNumber: map['roll_number'],
      classId: map['class_id'],
      faceData: map['face_data'],
    );
  }
}

class Class {
  final String? id;
  final String name;
  final String userId;

  Class({
    this.id,
    required this.name,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
    };
  }

  factory Class.fromMap(Map<String, dynamic> map) {
    return Class(
      id: map['id'],
      name: map['name'],
      userId: map['user_id'],
    );
  }
}

class Attendance {
  final String? id;
  final String studentId;
  final String classId;
  final DateTime date;
  final bool present;

  Attendance({
    this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.present,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'class_id': classId,
      'date': date.toIso8601String(),
      'present': present ? 1 : 0,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      studentId: map['student_id'],
      classId: map['class_id'],
      date: DateTime.parse(map['date']),
      present: map['present'] == 1,
    );
  }
}
