import 'package:flutter/material.dart';
import '../models/database_models.dart';
import '../services/database_helper.dart';
import 'view_attendance_records.dart';

class SelectClassRecordsScreen extends StatefulWidget {
  const SelectClassRecordsScreen({super.key});

  @override
  State<SelectClassRecordsScreen> createState() =>
      _SelectClassRecordsScreenState();
}

class _SelectClassRecordsScreenState extends State<SelectClassRecordsScreen> {
  List<Class> classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final loadedClasses = await DatabaseHelper.instance.getAllClasses();
    setState(() {
      classes = loadedClasses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Class'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(classes[index].name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewAttendanceRecordsScreen(classId: classes[index].id!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
