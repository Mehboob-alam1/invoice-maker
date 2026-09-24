// New packages needed:
//   google_fonts: ^6.2.1   (add to pubspec.yaml)
// New imports needed:
//   import 'package:google_fonts/google_fonts.dart';
//   import '../../core/theme/blue_theme.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_page_route.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings.dart';
import '../../services/invoice_parser.dart';
import '../../services/ocr_service.dart';
import '../../widgets/blue_screen.dart';
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
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Theme(
        data: buildBlueTheme(Theme.of(ctx)),
        child: _ScanSourceSheet(l10n: ctx.l10n),
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
      builder: (dialogCtx) => Theme(
        data: buildBlueTheme(Theme.of(dialogCtx)),
        child: const _ScanLoadingIndicator(),
      ),
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
  return Builder(
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: BlueColors.bright.withValues(alpha: isDark ? 0.0 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.file(
            File(path),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Bottom sheet: pick camera / gallery source. Responsive width, centered
// with a max width on wide (tablet/desktop) viewports.
// ---------------------------------------------------------------------------

class _ScanSourceSheet extends StatelessWidget {
  const _ScanSourceSheet({required this.l10n});

  final AppStrings l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width < 360 ? 12.0 : 20.0;
          final maxContentWidth = width >= 900 ? 640.0 : width;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  16 + bottomSafe,
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BlueColors.bright.withValues(alpha: isDark ? 0.0 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scanInvoice,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : BlueColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.scanInvoiceHelp,
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    _ScanOptionTile(
                      icon: Icons.photo_camera_rounded,
                      label: l10n.openCamera,
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                    const SizedBox(height: 10),
                    _ScanOptionTile(
                      icon: Icons.photo_library_rounded,
                      label: l10n.chooseGallery,
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One tappable option row: gradient icon tile + label + chevron.
// ---------------------------------------------------------------------------

class _ScanOptionTile extends StatelessWidget {
  const _ScanOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: scheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [BlueColors.bright, BlueColors.sky],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BlueColors.bright.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    letterSpacing: -0.1,
                    color: isDark ? Colors.white : BlueColors.navy,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading dialog shown while OCR runs.
// ---------------------------------------------------------------------------

class _ScanLoadingIndicator extends StatelessWidget {
  const _ScanLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 96,
        height: 96,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: BlueColors.bright.withValues(alpha: isDark ? 0.0 : 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(BlueColors.sky),
          ),
        ),
      ),
    );
  }
}