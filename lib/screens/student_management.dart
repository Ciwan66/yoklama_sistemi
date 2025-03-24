import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/database_models.dart';
import '../services/database_helper.dart';
import '../services/face_recognition_service.dart';

class StudentManagementScreen extends StatefulWidget {
  final int classId;

  const StudentManagementScreen({super.key, required this.classId});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  List<Student> students = [];
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _loadStudents() async {
    final loadedStudents =
        await DatabaseHelper.instance.getStudentsByClass(widget.classId);
    setState(() {
      students = loadedStudents;
    });
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _rollNumberController,
                decoration: const InputDecoration(labelText: 'Roll Number'),
              ),
            ],
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
                if (_nameController.text.isNotEmpty &&
                    _rollNumberController.text.isNotEmpty) {
                  final student = Student(
                    name: _nameController.text,
                    rollNumber: _rollNumberController.text,
                    classId: widget.classId,
                  );
                  await DatabaseHelper.instance.addStudent(student);
                  _nameController.clear();
                  _rollNumberController.clear();
                  Navigator.pop(context);
                  _loadStudents();
                  _showFaceRegistrationDialog();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showFaceRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register Face'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: _isCameraInitialized
                ? CameraPreview(_cameraController)
                : const CircularProgressIndicator(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _captureFace,
              child: const Text('Capture'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureFace() async {
    try {
      final image = await _cameraController.takePicture();
      final faceData = await _faceRecognitionService.getFaceData(image);

      // Update the last added student with face data
      final lastStudent = students.last;
      final updatedStudent = Student(
        id: lastStudent.id,
        name: lastStudent.name,
        rollNumber: lastStudent.rollNumber,
        classId: lastStudent.classId,
        faceData: faceData,
      );

      await DatabaseHelper.instance.updateStudent(updatedStudent);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face registered successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing face: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(students[index].name),
            subtitle: Text('Roll Number: ${students[index].rollNumber}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _cameraController.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }
}
