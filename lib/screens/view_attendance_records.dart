import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/database_models.dart';
import '../services/firestore_service.dart';

class ViewAttendanceRecordsScreen extends StatefulWidget {
  final String classId;
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
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loadedStudents =
          await _firestoreService.getStudentsByClass(widget.classId);
      final loadedAttendance = await _firestoreService.getAttendanceByDate(
          widget.classId, selectedDate);

      setState(() {
        students = loadedStudents;
        attendanceRecords = loadedAttendance;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
        title: const Text('Yoklama Kayıtları'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Tarih Seç',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? _buildNoStudentsView()
              : _buildAttendanceRecordsView(),
    );
  }

  Widget _buildNoStudentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bu Sınıfta Öğrenci Yok',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Yoklama kayıtlarını görüntülemek için önce öğrenci eklemelisiniz',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordsView() {
    // Özet bilgiler
    final totalStudents = students.length;
    final presentStudents =
        attendanceRecords.where((record) => record.present).length;
    final absentStudents = totalStudents - presentStudents;
    final attendanceRate = totalStudents > 0
        ? (presentStudents / totalStudents * 100).toStringAsFixed(1)
        : '0';

    return Column(
      children: [
        // Tarih ve özet
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.yMMMMd('tr_TR').format(selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryCard(
                    title: 'Toplam',
                    value: totalStudents.toString(),
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.people,
                  ),
                  _buildSummaryCard(
                    title: 'Mevcut',
                    value: presentStudents.toString(),
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                  _buildSummaryCard(
                    title: 'Yok',
                    value: absentStudents.toString(),
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                  _buildSummaryCard(
                    title: 'Oran',
                    value: '$attendanceRate%',
                    color: Theme.of(context).colorScheme.tertiary,
                    icon: Icons.pie_chart,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Öğrenci listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
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

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        attendance.present ? Colors.green : Colors.red[400],
                    child: Icon(
                      attendance.present ? Icons.check : Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Öğrenci No: ${student.rollNumber}'),
                  trailing: Chip(
                    label: Text(
                      attendance.present ? 'Mevcut' : 'Yok',
                      style: TextStyle(
                        color: attendance.present
                            ? Colors.green[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: attendance.present
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
