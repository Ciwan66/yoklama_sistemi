import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/database_models.dart';
import '../services/database_helper.dart';

class ViewAttendanceRecordsScreen extends StatefulWidget {
  final int classId;
  const ViewAttendanceRecordsScreen({super.key, required this.classId});

  @override
  State<ViewAttendanceRecordsScreen> createState() =>
      _ViewAttendanceRecordsScreenState();
}

class _ViewAttendanceRecordsScreenState
    extends State<ViewAttendanceRecordsScreen> {
  List<Student> students = [];
  List<Attendance> attendanceRecords = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedStudents =
        await DatabaseHelper.instance.getStudentsByClass(widget.classId);
    final loadedAttendance = await DatabaseHelper.instance
        .getAttendanceByDate(widget.classId, selectedDate);

    setState(() {
      students = loadedStudents;
      attendanceRecords = loadedAttendance;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final attendance = attendanceRecords.firstWhere(
                  (record) => record.studentId == student.id,
                  orElse: () => Attendance(
                    studentId: student.id!,
                    classId: widget.classId,
                    date: selectedDate,
                    present: false,
                  ),
                );

                return ListTile(
                  title: Text(student.name),
                  subtitle: Text('Roll Number: ${student.rollNumber}'),
                  trailing: Icon(
                    Icons.check_circle,
                    color: attendance.present ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
