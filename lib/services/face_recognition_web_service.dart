import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FaceRecognitionWebService {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isCameraInitialized = false;
  final StreamController<html.ImageData> _imageStreamController =
      StreamController<html.ImageData>.broadcast();

  Stream<html.ImageData> get imageStream => _imageStreamController.stream;

  // Web'de kamera durumunu kontrol et
  static Future<bool> isCameraAvailable() async {
    try {
      final devices =
          await html.window.navigator.mediaDevices?.enumerateDevices();
      return devices?.any((device) => device.kind == 'videoinput') ?? false;
    } catch (e) {
      print('Kamera kontrolü sırasında hata: $e');
      return false;
    }
  }

  // Web üzerinde kamerayı başlat (hata yönetimiyle geliştirilmiş)
  Future<bool> initializeCamera() async {
    if (_isCameraInitialized) return true;

    try {
      // Kamera izni kontrolü
      final cameraAvailable = await isCameraAvailable();
      if (!cameraAvailable) {
        print('Kamera bulunamadı veya erişilemedi');
        return false;
      }

      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.objectFit = 'cover'
        ..style.width = '100%'
        ..style.height = '100%';

      // Kamera izinlerini iste
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'user',
        },
        'audio': false,
      });

      if (_mediaStream == null) {
        print('Medya akışı alınamadı');
        return false;
      }

      _videoElement!.srcObject = _mediaStream;

      // Play() işlemini izle ve başarısız olursa hata döndür
      try {
        await _videoElement!.play();
      } catch (e) {
        print('Video oynatma başlatılamadı: $e');
        return false;
      }

      // Video elementi için view oluştur
      try {
        // ignore:undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(
          'webcamVideoElement',
          (int viewId) => _videoElement!,
        );
      } catch (e) {
        print('Video element görünümü oluşturulamadı: $e');
        return false;
      }

      _setupVideoProcessing();
      _isCameraInitialized = true;
      return true;
    } catch (e) {
      print('Kamera başlatılırken hata: $e');
      _cleanup(); // Hata durumunda temizlik yap
      return false;
    }
  }

  // Kamera kaynaklarını temizle
  void _cleanup() {
    if (_mediaStream != null) {
      for (final track in _mediaStream!.getTracks()) {
        track.stop();
      }
      _mediaStream = null;
    }
    _videoElement?.srcObject = null;
    _videoElement = null;
  }

  // Web kamera görüntüsü için Flutter widget'ı
  Widget buildWebCameraPreview() {
    if (!_isCameraInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Kamera başlatılamadı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lütfen kamera izinlerini kontrol edin veya manuel yoklama alın',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final success = await initializeCamera();
              if (success) {
                // Eğer bir setState fonksiyonu varsa, burada çağrılmalı
              }
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      );
    }

    try {
      return HtmlElementView(viewType: 'webcamVideoElement');
    } catch (e) {
      print('HtmlElementView oluşturulamadı: $e');
      return const Center(child: Text('Kamera gösterimi yüklenemedi'));
    }
  }

  // Düzenli aralıklarla kamera görüntüsünü işle
  void _setupVideoProcessing() {
    const duration = Duration(milliseconds: 200);
    Timer.periodic(duration, (timer) {
      if (_videoElement != null && _isCameraInitialized) {
        final canvas = html.CanvasElement(
          width: _videoElement!.videoWidth,
          height: _videoElement!.videoHeight,
        );
        canvas.context2D.drawImage(_videoElement!, 0, 0);
        final imageData =
            canvas.context2D.getImageData(0, 0, canvas.width!, canvas.height!);
        _imageStreamController.add(imageData);
      }
    });
  }

  // Kamerayı kapat
  void dispose() {
    _cleanup();
    _imageStreamController.close();
    _isCameraInitialized = false;
  }
}
