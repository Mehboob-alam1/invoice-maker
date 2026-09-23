import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/utils/invoice_layout_scale.dart';
import '../models/invoice_template.dart';
import 'invoice_gradient_theme.dart';

typedef InvoiceFontBuilder = TextStyle Function({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
});

class InvoiceTypography {
  static InvoiceFontBuilder _displayFont(InvoiceTemplateId id) {
    switch (id) {
      case InvoiceTemplateId.aurora:
        return GoogleFonts.poppins;
      case InvoiceTemplateId.sunset:
        return GoogleFonts.montserrat;
      case InvoiceTemplateId.ocean:
        return GoogleFonts.raleway;
      case InvoiceTemplateId.emerald:
        return GoogleFonts.playfairDisplay;
      case InvoiceTemplateId.royal:
        return GoogleFonts.merriweather;
      case InvoiceTemplateId.rose:
        return GoogleFonts.nunito;
      case InvoiceTemplateId.midnight:
        return GoogleFonts.spaceGrotesk;
      case InvoiceTemplateId.redModern:
        return GoogleFonts.playfairDisplay;
      case InvoiceTemplateId.blueYellow:
        return GoogleFonts.playfairDisplay;
      case InvoiceTemplateId.blueCorporate:
        return GoogleFonts.poppins;
      case InvoiceTemplateId.orangeReceipt:
        return GoogleFonts.poppins;
      default:
        return GoogleFonts.poppins;
    }
  }

  static TextTheme textTheme(
    Color baseColor, {
    double scale = 1.0,
    InvoiceTemplateId templateId = InvoiceTemplateId.midnight,
  }) {
    double s(double v) => (v * scale).clamp(v * 0.85, v);
    final display = _displayFont(templateId);
    return TextTheme(
      displaySmall: display(
        fontSize: s(20),
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      titleLarge: display(
        fontSize: s(16),
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.25,
      ),
      titleMedium: display(
        fontSize: s(13),
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: s(12.5),
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.35,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: s(11.5),
        fontWeight: FontWeight.w400,
        color: baseColor.withValues(alpha: 0.85),
        height: 1.35,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: s(10),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: baseColor.withValues(alpha: 0.6),
        height: 1.2,
      ),
    );
  }

  static ThemeData appTheme(InvoiceGradientTheme gradient, BuildContext context, {required InvoiceTemplateId templateId}) {
    final layout = InvoiceLayoutScale.of(context);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: gradient.accent, primary: gradient.accent),
      textTheme: textTheme(const Color(0xFF1E293B), scale: layout.scale, templateId: templateId),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }
}
