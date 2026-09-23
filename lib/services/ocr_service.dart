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
      return _orderedText(result).trim();
    } finally {
      await recognizer.close();
    }
  }

  /// Rebuilds OCR output in reading order (top-to-bottom, left-to-right) so
  /// invoice headers and line items stay grouped like the source document.
  static String _orderedText(RecognizedText result) {
    if (result.blocks.isEmpty) return result.text;

    final lines = <_OcrLine>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        lines.add(_OcrLine(text: line.text.trim(), top: box.top, left: box.left));
      }
    }
    lines.sort((a, b) {
      final dy = a.top.compareTo(b.top);
      if (dy.abs() > 12) return dy;
      return a.left.compareTo(b.left);
    });

    final buffer = StringBuffer();
    for (final line in lines) {
      if (line.text.isEmpty) continue;
      buffer.writeln(line.text);
    }
    final ordered = buffer.toString().trim();
    return ordered.isEmpty ? result.text.trim() : ordered;
  }
}

class _OcrLine {
  const _OcrLine({required this.text, required this.top, required this.left});
  final String text;
  final double top;
  final double left;
}
