import 'package:flutter/material.dart';
import '../models/database_models.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'view_attendance_records.dart';

class SelectClassRecordsScreen extends StatefulWidget {
  const SelectClassRecordsScreen({super.key});

  @override
  State<SelectClassRecordsScreen> createState() =>
      _SelectClassRecordsScreenState();
}

class _SelectClassRecordsScreenState extends State<SelectClassRecordsScreen> {
  List<Class> classes = [];
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (_authService.userId != null) {
      final loadedClasses =
          await _firestoreService.getAllClasses(_authService.userId!);
      setState(() {
        classes = loadedClasses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Class'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: classes.isEmpty
          ? const Center(child: Text('No classes found. Create a class first.'))
          : ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(classes[index].name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAttendanceRecordsScreen(
                            classId: classes[index].id!),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
