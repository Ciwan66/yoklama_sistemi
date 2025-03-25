import 'package:flutter/material.dart';

// Bu sınıf sadece mobil platformlarda kullanılacak olan fake bir implementasyon
class FaceRecognitionWebService {
  Future<bool> initializeCamera() async => false;
  Widget buildWebCameraPreview() => const SizedBox();
  void dispose() {}
}
