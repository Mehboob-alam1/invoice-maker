import 'package:flutter/material.dart';

import '../models/invoice_template.dart';

class InvoiceGradientTheme {
  final String name;
  final List<Color> gradientColors;
  final Color accent;
  final Color onGradient;

  const InvoiceGradientTheme({
    required this.name,
    required this.gradientColors,
    required this.accent,
    this.onGradient = Colors.white,
  });

  LinearGradient get headerGradient => LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class InvoiceThemes {
  static const aurora = InvoiceGradientTheme(
    name: 'Aurora',
    gradientColors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF97316)],
    accent: Color(0xFF7C3AED),
  );

  static const sunset = InvoiceGradientTheme(
    name: 'Sunset Coral',
    gradientColors: [Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFFB923C)],
    accent: Color(0xFFEA580C),
  );

  static const ocean = InvoiceGradientTheme(
    name: 'Ocean Blue',
    gradientColors: [Color(0xFF0EA5E9), Color(0xFF2563EB), Color(0xFF1E3A8A)],
    accent: Color(0xFF0284C7),
  );

  static const emerald = InvoiceGradientTheme(
    name: 'Emerald Growth',
    gradientColors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF34D399)],
    accent: Color(0xFF059669),
  );

  static const royal = InvoiceGradientTheme(
    name: 'Royal Indigo',
    gradientColors: [Color(0xFF4F46E5), Color(0xFF312E81), Color(0xFFCA8A04)],
    accent: Color(0xFF4338CA),
  );

  static const rose = InvoiceGradientTheme(
    name: 'Rose Gold',
    gradientColors: [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFFB7185)],
    accent: Color(0xFFBE123C),
  );

  static const midnight = InvoiceGradientTheme(
    name: 'Midnight Indigo',
    gradientColors: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF6366F1)],
    accent: Color(0xFF4338CA),
  );

  /// Matches free Classic / Modern / Minimal preview (app primary blue).
  static const classic = InvoiceGradientTheme(
    name: 'Classic',
    gradientColors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    accent: Color(0xFF2563EB),
  );

  static const all = [aurora, sunset, ocean, emerald, royal, rose, midnight];

  static InvoiceGradientTheme forTemplate(InvoiceTemplateId id) {
    switch (id) {
      case InvoiceTemplateId.aurora:
        return aurora;
      case InvoiceTemplateId.sunset:
        return sunset;
      case InvoiceTemplateId.ocean:
        return ocean;
      case InvoiceTemplateId.emerald:
        return emerald;
      case InvoiceTemplateId.royal:
        return royal;
      case InvoiceTemplateId.rose:
        return rose;
      case InvoiceTemplateId.midnight:
        return midnight;
      default:
        return midnight;
    }
  }
}
