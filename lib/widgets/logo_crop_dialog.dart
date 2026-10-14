import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Center-crops a picked photo. The slider zooms in before the square is saved.
class LogoCropDialog extends StatefulWidget {
  const LogoCropDialog({super.key, required this.bytes});

  final List<int> bytes;

  static Future<List<int>?> show(BuildContext context, List<int> bytes) {
    return showDialog<List<int>>(
      context: context,
      builder: (context) => LogoCropDialog(bytes: bytes),
    );
  }

  @override
  State<LogoCropDialog> createState() => _LogoCropDialogState();
}

class _LogoCropDialogState extends State<LogoCropDialog> {
  ui.Image? _image;
  double _zoom = 1;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(widget.bytes));
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _image = frame.image);
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null) return;
    const side = 512.0;
    final shortest = image.width < image.height ? image.width.toDouble() : image.height.toDouble();
    final crop = shortest / _zoom;
    final src = Rect.fromCenter(
      center: Offset(image.width / 2, image.height / 2),
      width: crop,
      height: crop,
    );
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(image, src, const Rect.fromLTWH(0, 0, side, side), Paint());
    final out = await recorder.endRecording().toImage(side.toInt(), side.toInt());
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted || data == null) return;
    Navigator.pop(context, data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final image = _image;
    return AlertDialog(
      title: Text(strings.cropLogo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: image == null
                ? const Center(child: CircularProgressIndicator())
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      painter: _CropPainter(image, _zoom),
                      child: const SizedBox.expand(),
                    ),
                  ),
          ),
          Slider(
            value: _zoom,
            min: 1,
            max: 3,
            onChanged: (value) => setState(() => _zoom = value),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.cancel)),
        FilledButton(onPressed: image == null ? null : _save, child: Text(strings.usePhoto)),
      ],
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.image, this.zoom);
  final ui.Image image;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = image.width < image.height ? image.width.toDouble() : image.height.toDouble();
    final crop = shortest / zoom;
    final src = Rect.fromCenter(
      center: Offset(image.width / 2, image.height / 2),
      width: crop,
      height: crop,
    );
    canvas.drawImageRect(image, src, Offset.zero & size, Paint());
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) => oldDelegate.zoom != zoom;
}
