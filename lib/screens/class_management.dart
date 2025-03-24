import 'package:flutter/material.dart';
import '../models/database_models.dart';
import '../services/database_helper.dart';
import '../screens/student_management.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final TextEditingController _classNameController = TextEditingController();
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
                await DatabaseHelper.instance.deleteClass(classes[index].id!);
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
                  await DatabaseHelper.instance.addClass(
                    Class(name: _classNameController.text),
                  );
                  _classNameController.clear();
                  Navigator.pop(context);
                  _loadClasses();
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
