import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  OcrService._();

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  static Future<String> recognizeText(String imagePath) async {
    if (!isSupported) {
      throw UnsupportedError('OCR is available on Android and iOS only.');
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
