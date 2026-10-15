import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Logo on the left, signature and stamp on the right. Each image stays inside its slot.
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
    this.logoHeight = 48,
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
        if (_hasLogo)
          Expanded(
            flex: 5,
            child: _slot(logoPath, logoBytes, logoHeight, Alignment.centerLeft),
          )
        else
          const Spacer(flex: 5),
        if (_hasSignature) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _slot(signaturePath, signatureBytes, markHeight, Alignment.centerRight),
          ),
        ],
        if (_hasStamp) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _slot(stampPath, stampBytes, markHeight, Alignment.centerRight),
          ),
        ],
      ],
    );
  }

  Widget _slot(String path, List<int>? bytes, double height, Alignment alignment) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: _image(path, bytes, alignment),
    );
  }

  Widget _image(String path, List<int>? bytes, Alignment alignment) {
    final memory = bytes;
    if (memory != null && memory.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(memory),
        fit: BoxFit.contain,
        alignment: alignment,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
    if (path.isEmpty) return const SizedBox.shrink();
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      alignment: alignment,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
