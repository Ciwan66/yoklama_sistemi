import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/database_models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE classes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        user_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        roll_number TEXT NOT NULL,
        class_id INTEGER NOT NULL,
        face_data TEXT,
        FOREIGN KEY (class_id) REFERENCES classes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        class_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        present INTEGER NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id),
        FOREIGN KEY (class_id) REFERENCES classes (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE classes ADD COLUMN user_id TEXT DEFAULT ""');
    }
  }

  // Class operations
  Future<int> addClass(Class classItem) async {
    final db = await database;
    return db.insert('classes', classItem.toMap());
  }

  Future<List<Class>> getAllClasses(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'classes',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Class.fromMap(maps[i]));
  }

  Future<void> deleteClass(int id) async {
    final db = await database;
    await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  // Student operations
  Future<int> addStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> getStudentsByClass(int classId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'class_id = ?',
      whereArgs: [classId],
    );
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  // Attendance operations
  Future<void> markAttendance(Attendance attendance) async {
    final db = await database;

    // First, check if an attendance record already exists for this student on this date
    final existingRecord = await db.query(
      'attendance',
      where: 'student_id = ? AND class_id = ? AND date = ?',
      whereArgs: [
        attendance.studentId,
        attendance.classId,
        attendance.date
            .toIso8601String()
            .split('T')[0], // Use only the date part
      ],
    );

    if (existingRecord.isEmpty) {
      // If no record exists, insert new record
      await db.insert('attendance', {
        ...attendance.toMap(),
        'date': attendance.date
            .toIso8601String()
            .split('T')[0], // Store only the date
      });
    } else {
      // If record exists, update it
      await db.update(
        'attendance',
        {'present': attendance.present ? 1 : 0},
        where: 'student_id = ? AND class_id = ? AND date = ?',
        whereArgs: [
          attendance.studentId,
          attendance.classId,
          attendance.date.toIso8601String().split('T')[0],
        ],
      );
    }
  }

  Future<List<Attendance>> getAttendanceByDate(
      int classId, DateTime date) async {
    final db = await database;
    final dateStr =
        date.toIso8601String().split('T')[0]; // Use only the date part

    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'class_id = ? AND date = ?',
      whereArgs: [classId, dateStr],
    );

    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<void> updateStudent(Student student) async {
    final db = await database;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }
}
