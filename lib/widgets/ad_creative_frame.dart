import 'package:flutter/material.dart';

/// Full-width frame around a native ad, with no text label.
class AdCreativeFrame extends StatelessWidget {
  const AdCreativeFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
