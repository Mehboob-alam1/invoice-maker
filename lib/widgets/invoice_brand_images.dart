import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Logo on the left, signature (and Pro stamp) on the right.
class InvoiceBrandImages extends StatelessWidget {
  const InvoiceBrandImages({
    super.key,
    this.logoPath = '',
    this.signaturePath = '',
    this.stampPath = '',
    this.showStamp = false,
    this.logoBytes,
    this.signatureBytes,
    this.stampBytes,
    this.logoHeight = 52,
    this.markHeight = 44,
  });

  final String logoPath;
  final String signaturePath;
  final String stampPath;
  final bool showStamp;
  final List<int>? logoBytes;
  final List<int>? signatureBytes;
  final List<int>? stampBytes;
  final double logoHeight;
  final double markHeight;

  bool get _hasLogo => logoPath.isNotEmpty || (logoBytes != null && logoBytes!.isNotEmpty);
  bool get _hasSignature => signaturePath.isNotEmpty || (signatureBytes != null && signatureBytes!.isNotEmpty);
  bool get _hasStamp => showStamp && (stampPath.isNotEmpty || (stampBytes != null && stampBytes!.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    if (!_hasLogo && !_hasSignature && !_hasStamp) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_hasLogo) _image(logoPath, logoBytes, logoHeight),
        const Spacer(),
        if (_hasSignature) _image(signaturePath, signatureBytes, markHeight),
        if (_hasStamp)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _image(stampPath, stampBytes, markHeight),
          ),
      ],
    );
  }

  Widget _image(String path, List<int>? bytes, double height) {
    final memory = bytes;
    if (memory != null && memory.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(memory),
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
    return Image.file(
      File(path),
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
