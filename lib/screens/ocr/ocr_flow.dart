import 'dart:io';

import 'package:flutter/material.dart';

import '../../navigation/app_page_route.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings.dart';
import '../../services/invoice_parser.dart';
import '../../services/ocr_service.dart';
import 'ocr_review_screen.dart';

Future<void> startOcrScan(BuildContext context) async {
  final strings = AppStrings.read(context);
  if (!OcrService.isSupported) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.ocrMobileOnly)),
    );
    return;
  }

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = ctx.l10n;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.scanInvoice, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(l10n.scanInvoiceHelp),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(l10n.openCamera),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.chooseGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null || !context.mounted) return;

  var loadingShown = false;
  try {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 100);
    if (picked == null || !context.mounted) return;

    loadingShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final text = await OcrService.recognizeText(picked.path);
    if (!context.mounted) return;
    if (loadingShown) {
      Navigator.of(context).pop();
      loadingShown = false;
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.read(context).noTextFound)),
      );
      return;
    }

    final parsed = InvoiceParser.parse(text, imagePath: picked.path);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      appPageRoute(
        OcrReviewScreen(parsed: parsed),
        adScopeKey: 'ocr_review_${parsed.hashCode}',
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    if (loadingShown) Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.read(context).couldNotScan('$error'))),
    );
  }
}

Widget scannedImagePreview(String? path) {
  if (path == null) return const SizedBox.shrink();
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.file(
      File(path),
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}
