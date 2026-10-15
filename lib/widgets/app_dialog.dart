import 'package:flutter/material.dart';

import '../core/theme/blue_theme.dart';

enum AppDialogTone { primary, success, warning, danger }

enum AppDialogActionStyle { filled, outlined, text }

class AppDialogAction {
  const AppDialogAction({
    required this.label,
    this.onPressed,
    this.icon,
    this.style = AppDialogActionStyle.filled,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppDialogActionStyle style;
  final bool destructive;
}

/// Shared popup used across the app: gradient badge, calm type, full-width actions.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.icon,
    this.tone = AppDialogTone.primary,
    required this.title,
    this.message,
    this.body,
    this.actions = const [],
  });

  final IconData? icon;
  final AppDialogTone tone;
  final String title;
  final String? message;
  final Widget? body;
  final List<AppDialogAction> actions;

  List<Color> get _colors {
    switch (tone) {
      case AppDialogTone.success:
        return const [Color(0xFF16A34A), Color(0xFF059669)];
      case AppDialogTone.warning:
        return const [Color(0xFFF59E0B), Color(0xFFEA580C)];
      case AppDialogTone.danger:
        return const [Color(0xFFEF4444), Color(0xFFB91C1C)];
      case AppDialogTone.primary:
        return const [BlueColors.seed, BlueColors.deep];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = _colors;
    final muted = scheme.onSurfaceVariant;

    final input = theme.inputDecorationTheme;
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: input.copyWith(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      child: Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.16),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 88,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.first.withValues(alpha: 0.16),
                            colors.first.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (icon != null) ...[
                          Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.first.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: scheme.onSurface,
                          ),
                        ),
                        if (message != null && message!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: muted,
                            ),
                          ),
                        ],
                        if (body != null) ...[
                          const SizedBox(height: 12),
                          body!,
                        ],
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          for (var i = 0; i < actions.length; i++) ...[
                            if (i > 0) const SizedBox(height: 4),
                            _ActionButton(action: actions[i], scheme: scheme),
                          ],
                        ],
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.scheme});

  final AppDialogAction action;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    const textStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 14);
    final icon = action.icon;

    switch (action.style) {
      case AppDialogActionStyle.text:
        final style = TextButton.styleFrom(
          foregroundColor: action.destructive ? scheme.error : scheme.onSurfaceVariant,
          textStyle: textStyle,
          padding: const EdgeInsets.symmetric(vertical: 6),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        return SizedBox(
          width: double.infinity,
          child: icon == null
              ? TextButton(onPressed: action.onPressed, style: style, child: Text(action.label))
              : TextButton.icon(
                  onPressed: action.onPressed,
                  style: style,
                  icon: Icon(icon, size: 18),
                  label: Text(action.label),
                ),
        );
      case AppDialogActionStyle.outlined:
        final style = OutlinedButton.styleFrom(
          foregroundColor: action.destructive ? scheme.error : scheme.primary,
          minimumSize: const Size.fromHeight(42),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(
            color: (action.destructive ? scheme.error : scheme.primary).withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textStyle,
        );
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: icon == null
              ? OutlinedButton(onPressed: action.onPressed, style: style, child: Text(action.label))
              : OutlinedButton.icon(
                  onPressed: action.onPressed,
                  style: style,
                  icon: Icon(icon, size: 18),
                  label: Text(action.label),
                ),
        );
      case AppDialogActionStyle.filled:
        final bg = action.destructive ? scheme.error : scheme.primary;
        final fg = action.destructive ? scheme.onError : scheme.onPrimary;
        final style = FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: fg.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(42),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textStyle,
        );
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: icon == null
              ? FilledButton(onPressed: action.onPressed, style: style, child: Text(action.label))
              : FilledButton.icon(
                  onPressed: action.onPressed,
                  style: style,
                  icon: Icon(icon, size: 18),
                  label: Text(action.label),
                ),
        );
    }
  }
}
