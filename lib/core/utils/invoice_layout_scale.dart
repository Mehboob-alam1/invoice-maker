import 'package:flutter/material.dart';

/// Responsive typography and layout helpers for invoice templates on any screen width.
class InvoiceLayoutScale {
  InvoiceLayoutScale._(this.width);

  final double width;

  factory InvoiceLayoutScale.of(BuildContext context) {
    return InvoiceLayoutScale._(MediaQuery.sizeOf(context).width);
  }

  /// 0.85–1.0; caps growth on tablets so type stays readable, not huge.
  double get scale {
    if (width >= 820) return 1.0;
    if (width >= 600) return 0.96;
    return (width / 390).clamp(0.85, 0.96);
  }

  double sp(double size) => (size * scale).clamp(size * 0.85, size);

  double get horizontalPadding => sp(16).clamp(12, 24);

  double get verticalPadding => sp(14).clamp(10, 22);

  bool get compact => width < 400;

  bool get stackHeader => width < 380;

  bool get stackParties => width < 420;

  double get totalsMaxWidth => compact ? width : 300 * scale;

  double get tableMinWidth => compact ? width * 2.4 : 0;
}

/// Prevents overflow: wraps long invoice text with ellipsis where needed.
class InvoiceText extends StatelessWidget {
  const InvoiceText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = true,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
