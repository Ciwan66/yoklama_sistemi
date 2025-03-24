import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;

class FaceRecognitionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

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

  void dispose() {
    _faceDetector.close();
  }
}
