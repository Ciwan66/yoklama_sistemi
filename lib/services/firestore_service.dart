import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/database_models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sınıf işlemleri
  Future<String> addClass(Class classItem) async {
    final docRef = await _firestore.collection('classes').add({
      'name': classItem.name,
      'user_id': classItem.userId,
    });
    return docRef.id;
  }

  Future<List<Class>> getAllClasses(String userId) async {
    final snapshot = await _firestore
        .collection('classes')
        .where('user_id', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Class(
        id: doc.id,
        name: data['name'],
        userId: data['user_id'],
      );
    }).toList();
  }

  Future<void> deleteClass(String classId) async {
    await _firestore.collection('classes').doc(classId).delete();

    // İlgili sınıfa ait öğrencileri sil
    final studentSnapshot = await _firestore
        .collection('students')
        .where('class_id', isEqualTo: classId)
        .get();

    for (var doc in studentSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Öğrenci işlemleri
  Future<String> addStudent(Student student) async {
    final docRef = await _firestore.collection('students').add({
      'name': student.name,
      'roll_number': student.rollNumber,
      'class_id': student.classId,
      'face_data': student.faceData,
    });
    return docRef.id;
  }

  Future<List<Student>> getStudentsByClass(String classId) async {
    final snapshot = await _firestore
        .collection('students')
        .where('class_id', isEqualTo: classId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Student(
        id: doc.id,
        name: data['name'],
        rollNumber: data['roll_number'],
        classId: classId,
        faceData: data['face_data'],
      );
    }).toList();
  }

  Future<void> updateStudent(Student student) async {
    await _firestore.collection('students').doc(student.id).update({
      'name': student.name,
      'roll_number': student.rollNumber,
      'face_data': student.faceData,
    });
  }

  // Yoklama işlemleri
  Future<void> markAttendance(Attendance attendance) async {
    final dateStr = attendance.date.toIso8601String().split('T')[0];
    final docId = '${attendance.studentId}_${attendance.classId}_$dateStr';

    await _firestore.collection('attendance').doc(docId).set({
      'student_id': attendance.studentId,
      'class_id': attendance.classId,
      'date': dateStr,
      'present': attendance.present,
    });
  }

  Future<List<Attendance>> getAttendanceByDate(
      String classId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final snapshot = await _firestore
        .collection('attendance')
        .where('class_id', isEqualTo: classId)
        .where('date', isEqualTo: dateStr)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Attendance(
        id: doc.id,
        studentId: data['student_id'],
        classId: data['class_id'],
        date: DateTime.parse(data['date']),
        present: data['present'],
      );
    }).toList();
  }
}
