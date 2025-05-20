import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/database_models.dart';
import '../services/firestore_service.dart';
import '../services/face_recognition_service.dart';

class StudentManagementScreen extends StatefulWidget {
  final String classId;

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
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  Student? _selectedStudent;

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
    setState(() {
      _isLoading = true;
    });

    final loadedStudents =
        await _firestoreService.getStudentsByClass(widget.classId);

    setState(() {
      students = loadedStudents;
      _isLoading = false;
    });
  }

  void _showAddStudentDialog() {
    _nameController.clear();
    _rollNumberController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Öğrenci Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Öğrenci Adı',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _rollNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Öğrenci Numarası',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty &&
                    _rollNumberController.text.isNotEmpty) {
                  final student = Student(
                    name: _nameController.text,
                    rollNumber: _rollNumberController.text,
                    classId: widget.classId,
                  );
                  final studentId = await _firestoreService.addStudent(student);
                  _nameController.clear();
                  _rollNumberController.clear();
                  Navigator.pop(context);

                  final newStudent = Student(
                    id: studentId,
                    name: student.name,
                    rollNumber: student.rollNumber,
                    classId: student.classId,
                  );

                  setState(() {
                    students.add(newStudent);
                    _selectedStudent = newStudent;
                  });

                  // Yüz kaydı için kamera ekranını göster
                  _showFaceRegistrationDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showFaceRegistrationDialog() {
    if (_selectedStudent == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yüz Kaydı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_selectedStudent!.name} için yüz kaydı yapın'),
              const SizedBox(height: 16),
              if (_isCameraInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 300,
                    width: 300,
                    child: CameraPreview(_cameraController),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 16),
              const Text(
                'Yüzünüzü kameraya bakarak sabit tutun ve "Kaydet" düğmesine basın.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedStudent = null;
                });
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: _captureFace,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureFace() async {
    if (_selectedStudent == null) return;

    try {
      final image = await _cameraController.takePicture();
      final faceData = await _faceRecognitionService.getFaceData(image);

      // Update the student with face data
      final updatedStudent = Student(
        id: _selectedStudent!.id,
        name: _selectedStudent!.name,
        rollNumber: _selectedStudent!.rollNumber,
        classId: _selectedStudent!.classId,
        faceData: faceData,
      );

      await _firestoreService.updateStudent(updatedStudent);
      Navigator.pop(context);

      setState(() {
        _selectedStudent = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Yüz kaydı başarıyla tamamlandı'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      setState(() {
        _selectedStudent = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Yüz kaydı sırasında hata: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci Yönetimi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? _buildEmptyState()
              : _buildStudentList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Öğrenci Ekle'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'Henüz Öğrenci Yok',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk öğrencinizi eklemek için aşağıdaki butona tıklayın',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddStudentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Öğrenci Ekle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(student.name),
            subtitle: Text('Öğrenci No: ${student.rollNumber}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(student),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Öğrenciyi Sil'),
          content: Text(
              '${student.name} adlı öğrenciyi silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteStudent(student);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStudent(Student student) async {
    if (student.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğrenci ID bulunamadı')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.deleteStudent(student.id!);

      setState(() {
        students.removeWhere((s) => s.id == student.id);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.name} başarıyla silindi')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öğrenci silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _nameController.dispose();
    _rollNumberController.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }
}
