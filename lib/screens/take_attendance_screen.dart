import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/database_models.dart';
import '../services/database_helper.dart';
import '../services/face_recognition_service.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final int classId;
  const TakeAttendanceScreen({super.key, required this.classId});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  List<Student> students = [];
  Set<int> presentStudents = {};

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadStudents();
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

  Future<void> _markAttendance() async {
    try {
      if (!_isCameraInitialized) return;

      final image = await _cameraController.takePicture();
      final currentFaceData = await _faceRecognitionService.getFaceData(image);

      if (currentFaceData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected')),
        );
        return;
      }

      for (final student in students) {
        if (student.faceData != null) {
          final isMatch = await _faceRecognitionService.compareFaces(
            student.faceData,
            currentFaceData,
          );

          if (isMatch) {
            await DatabaseHelper.instance.markAttendance(
              Attendance(
                studentId: student.id!,
                classId: widget.classId,
                date: DateTime.now(),
                present: true,
              ),
            );

            setState(() {
              presentStudents.add(student.id!);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Attendance marked for ${student.name}')),
            );
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching student found')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _saveAttendance() async {
    final now = DateTime.now();
    for (final student in students) {
      await DatabaseHelper.instance.markAttendance(
        Attendance(
          studentId: student.id!,
          classId: widget.classId,
          date: now,
          present: presentStudents.contains(student.id),
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAttendance,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isCameraInitialized)
            SizedBox(
              height: 400,
              child: CameraPreview(_cameraController),
            )
          else
            const CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
                  title: Text(student.name),
                  subtitle: Text('Roll Number: ${student.rollNumber}'),
                  trailing: Icon(
                    Icons.check_circle,
                    color: presentStudents.contains(student.id)
                        ? Colors.green
                        : Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _markAttendance,
        child: const Icon(Icons.camera),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }
}
