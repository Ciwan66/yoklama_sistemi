import 'package:flutter/material.dart';
import '../models/database_models.dart';
import '../services/database_helper.dart';
import '../screens/student_management.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final TextEditingController _classNameController = TextEditingController();
  List<Class> classes = [];
  final _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

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

  Future<void> _addClass(String className) async {
    if (_authService.userId != null) {
      await _firestoreService.addClass(
        Class(
          name: className,
          userId: _authService.userId!,
        ),
      );
      _loadClasses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(classes[index].name),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await _firestoreService.deleteClass(classes[index].id!);
                _loadClasses();
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentManagementScreen(classId: classes[index].id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Class'),
          content: TextField(
            controller: _classNameController,
            decoration: const InputDecoration(
              labelText: 'Class Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_classNameController.text.isNotEmpty) {
                  await _addClass(_classNameController.text);
                  _classNameController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }
}
