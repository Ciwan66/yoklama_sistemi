import 'package:flutter/material.dart';
import 'screens/class_management.dart';
import 'screens/select_class_attendance.dart';
import 'screens/select_class_records.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMenuButton(
              context,
              'Manage Classes',
              Icons.class_,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Take Attendance',
              Icons.camera_alt,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectClassAttendanceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'View Records',
              Icons.assessment,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectClassRecordsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
