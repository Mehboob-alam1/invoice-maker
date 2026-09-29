import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/blue_theme.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final titleColor = isDark ? scheme.onSurface : BlueColors.navy;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.25).toDouble();
    final iconSize = 56.0 * textScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = constraints.maxWidth < 360 ? 20.0 : 28.0;
        final minHeight = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight > 48 ? minHeight - 48 : 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: iconSize, color: scheme.primary.withValues(alpha: 0.85)),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          height: 1.25,
                          color: titleColor,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                          color: muted ?? scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 24),
                      BlueGradientButton(label: actionLabel!, onPressed: onAction!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
