import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/database_models.dart';
import '../services/firestore_service.dart';
import '../services/face_recognition_service.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final String classId;
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
  Set<String> presentStudents = {};
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  bool _isProcessing = false;

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

  Future<void> _markAttendance() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (!_isCameraInitialized) return;

      final image = await _cameraController.takePicture();
      final currentFaceData = await _faceRecognitionService.getFaceData(image);

      if (currentFaceData == null) {
        _showErrorSnackBar('Yüz algılanamadı. Lütfen tekrar deneyin.');
        return;
      }

      bool faceMatched = false;

      for (final student in students) {
        if (student.faceData != null) {
          final isMatch = await _faceRecognitionService.compareFaces(
            student.faceData,
            currentFaceData,
          );

          if (isMatch) {
            await _firestoreService.markAttendance(
              Attendance(
                studentId: student.id!,
                classId: widget.classId,
                date: DateTime.now(),
                present: true,
              ),
            );

            setState(() {
              presentStudents.add(student.id!);
              faceMatched = true;
            });

            _showSuccessSnackBar('${student.name} için yoklama alındı!');
            break;
          }
        }
      }

      if (!faceMatched) {
        _showErrorSnackBar(
            'Eşleşen öğrenci bulunamadı. Lütfen tekrar deneyin veya manuel yoklama alın.');
      }
    } catch (e) {
      _showErrorSnackBar('Hata: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    final now = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Yoklama kaydediliyor...'),
          ],
        ),
      ),
    );

    try {
      for (final student in students) {
        await _firestoreService.markAttendance(
          Attendance(
            studentId: student.id!,
            classId: widget.classId,
            date: now,
            present: presentStudents.contains(student.id),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context); // Dialog'u kapat
        Navigator.pop(context); // Ekranı kapat

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yoklama başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dialog'u kapat
        _showErrorSnackBar('Yoklama kaydedilirken hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yoklama Al'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAttendance,
            tooltip: 'Yoklamayı Kaydet',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? _buildNoStudentsView()
              : _buildAttendanceView(),
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
              'Yoklama almak için önce öğrenci eklemelisiniz',
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

  Widget _buildAttendanceView() {
    return Column(
      children: [
        if (_isCameraInitialized)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CameraPreview(_cameraController),
                    if (_isProcessing)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 16,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _markAttendance,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Yoklama Al'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          const Expanded(
            flex: 3,
            child: Center(child: CircularProgressIndicator()),
          ),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Öğrenci Listesi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Mevcut: ${presentStudents.length}/${students.length}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isPresent = presentStudents.contains(student.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isPresent ? Colors.green : Colors.grey[400],
                            child: Icon(
                              isPresent ? Icons.check : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Öğrenci No: ${student.rollNumber}'),
                          trailing: Switch(
                            value: isPresent,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                if (value) {
                                  presentStudents.add(student.id!);
                                } else {
                                  presentStudents.remove(student.id);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }
}
