import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/app_strings.dart';

/// Draws a signature and returns PNG bytes.
class SignaturePadDialog extends StatefulWidget {
  const SignaturePadDialog({super.key});

  static Future<List<int>?> show(BuildContext context) {
    return showDialog<List<int>>(
      context: context,
      builder: (context) => const SignaturePadDialog(),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final _lines = <List<Offset>>[];
  final _boundary = GlobalKey();

  void _start(Offset point) => setState(() => _lines.add([point]));

  void _move(Offset point) {
    if (_lines.isEmpty) return;
    setState(() => _lines.last.add(point));
  }

  Future<void> _save() async {
    final boundary = _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted || data == null) return;
    Navigator.pop(context, data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return AlertDialog(
      title: Text(strings.signature),
      content: SizedBox(
        width: 320,
        height: 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onPanStart: (details) => _start(details.localPosition),
              onPanUpdate: (details) => _move(details.localPosition),
              child: RepaintBoundary(
                key: _boundary,
                child: CustomPaint(
                  painter: _SignaturePainter(_lines),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(_lines.clear),
          child: Text(strings.clearSignature),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.cancel)),
        FilledButton(onPressed: _lines.isEmpty ? null : _save, child: Text(strings.save)),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.lines);
  final List<List<Offset>> lines;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = const Color(0xFF14141F)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final line in lines) {
      if (line.length < 2) continue;
      final path = Path()..moveTo(line.first.dx, line.first.dy);
      for (final point in line.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
