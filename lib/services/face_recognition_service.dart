import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'face_recognition_stub.dart'
    if (dart.library.html) 'face_recognition_web_service.dart';

class FaceRecognitionService {
  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
    ),
  );

  // Web için servis
  final _webService = kIsWeb ? FaceRecognitionWebService() : null;

  // Kamera servisi initialize olmuş mu
  bool _isInitialized = false;
  // Mobil için
  CameraController? _cameraController;

  // Servisi platform'a göre başlat
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (kIsWeb) {
      // Web platformunda
      _isInitialized = await _webService!.initializeCamera();
      return _isInitialized;
    } else {
      // Mobil platformlarda
      try {
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
        await _cameraController!.initialize();
        _isInitialized = true;
        return true;
      } catch (e) {
        print('Kamera başlatılamadı: $e');
        _isInitialized = false;
        return false;
      }
    }
  }

  // Kamera Önizleme Widget'ı - Platform'a göre farklı
  Widget buildPreview() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kIsWeb) {
      return _webService!.buildWebCameraPreview();
    } else {
      return CameraPreview(_cameraController!);
    }
  }

  // Görüntü yakalama - Web'de ve mobilde farklı çalışır
  Future<List<double>?> captureFace() async {
    if (!_isInitialized) return null;

    try {
      if (kIsWeb) {
        // Web'de yüz tanıma (basit bir simülasyon)
        return List.generate(128, (index) => (index % 10) / 10); // Yapay veri
      } else {
        // Mobil platformda yüz tanıma
        final image = await _cameraController!.takePicture();
        // Burada mobil için gerçek yüz tanıma işlemleri yapılır
        return List.generate(128, (index) => (index % 10) / 10); // Yapay veri
      }
    } catch (e) {
      print('Yüz yakalama hatası: $e');
      return null;
    }
  }

  Future<String?> getFaceData(XFile image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) return null;

      final face = faces.first;
      return '${face.boundingBox.left},${face.boundingBox.top},${face.boundingBox.right},${face.boundingBox.bottom}';
    } catch (e) {
      print('Error getting face data: $e');
      return null;
    }
  }

  Future<bool> compareFaces(
      String? storedFaceData, String? currentFaceData) async {
    if (storedFaceData == null || currentFaceData == null) return false;

    try {
      final stored = storedFaceData.split(',').map(double.parse).toList();
      final current = currentFaceData.split(',').map(double.parse).toList();

      // Calculate overlap of bounding boxes
      final overlap = _calculateOverlap(stored, current);
      return overlap > 0.6; // Adjust threshold as needed
    } catch (e) {
      print('Error comparing faces: $e');
      return false;
    }
  }

  double _calculateOverlap(List<double> box1, List<double> box2) {
    final intersectionArea = _getIntersectionArea(box1, box2);
    final union = _getArea(box1) + _getArea(box2) - intersectionArea;
    return union > 0 ? intersectionArea / union : 0;
  }

  double _getArea(List<double> box) {
    return (box[2] - box[0]) * (box[3] - box[1]);
  }

  double _getIntersectionArea(List<double> box1, List<double> box2) {
    final left = math.max(box1[0], box2[0]);
    final top = math.max(box1[1], box2[1]);
    final right = math.min(box1[2], box2[2]);
    final bottom = math.min(box1[3], box2[3]);

    if (left < right && top < bottom) {
      return (right - left) * (bottom - top);
    }
    return 0;
  }

  // Kaynakları temizle
  void dispose() {
    if (kIsWeb) {
      _webService?.dispose();
    } else {
      _cameraController?.dispose();
    }
    _isInitialized = false;
    _faceDetector.close();
  }
}
