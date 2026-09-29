import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide Space Grotesk typography.
TextTheme spaceGroteskTextTheme([TextTheme? base]) {
  return GoogleFonts.spaceGroteskTextTheme(base ?? ThemeData.light().textTheme);
}

TextStyle spaceGrotesk({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.spaceGrotesk(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}
