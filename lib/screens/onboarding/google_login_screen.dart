import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/app_page_route.dart';
import '../../providers/invoice_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../business_setup/business_name_screen.dart';

/// Shown once after onboarding carousel — optional Google sign-in before business setup.
class GoogleLoginScreen extends StatelessWidget {
  const GoogleLoginScreen({super.key});

  void _continue(BuildContext context) {
    context.read<InvoiceProvider>().completeOnboardingGoogleStep();
    Navigator.of(context).pushReplacement(appPageRoute(const BusinessNameScreen()));
  }

  Future<void> _signIn(BuildContext context) async {
    final auth = context.read<AuthService>();
    final strings = AppStrings.read(context);
    final ok = await auth.signInWithGoogle();
    if (!context.mounted) return;
    if (!ok && auth.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError!)));
      return;
    }
    if (auth.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.googleSignInSuccess)),
      );
      _continue(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // buildBlueTheme is expected to use base.copyWith(...) so extensions such
    // as AppSemanticColors survive.
    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(builder: (innerContext) => _buildBody(innerContext)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final strings = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.extension<AppSemanticColors>()?.textMuted ?? cs.onSurfaceVariant;
    final titleColor = isDark ? cs.onSurface : BlueColors.navy;
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final gradient = <Color>[BlueColors.seed, BlueColors.sky];

    final actions = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user != null) ...[
          _SignedInCard(user: user, muted: muted, gradient: gradient),
          const SizedBox(height: 16),
          BlueGradientButton(
            label: strings.continueLabel,
            onPressed: () => _continue(context),
          ),
        ] else
          _GoogleSignInButton(
            loading: auth.signingIn,
            label: strings.signInWithGoogle,
            onPressed: auth.signingIn ? null : () => _signIn(context),
          ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: auth.signingIn ? null : () => _continue(context),
            style: TextButton.styleFrom(
              foregroundColor: muted,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: Text(strings.skipGoogleLogin, textAlign: TextAlign.center),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppPageShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final wide = w >= 900;
              final hPad = w < 360 ? 16.0 : (w < 700 ? 24.0 : 32.0);
              final maxW = wide ? 1040.0 : (w >= 700 ? 560.0 : 480.0);

              final header = _Header(
                title: strings.googleLoginTitle,
                subtitle: strings.googleLoginSubtitle,
                titleColor: titleColor,
                muted: muted,
                large: wide,
              );

              final Widget content;
              if (wide) {
                content = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HeroBadge(gradient: gradient, size: 112),
                          const SizedBox(height: 28),
                          header,
                        ],
                      ),
                    ),
                    const SizedBox(width: 56),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: actions,
                      ),
                    ),
                  ],
                );
              } else {
                content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _HeroBadge(gradient: gradient, size: w < 360 ? 84 : 96),
                    ),
                    SizedBox(height: w < 360 ? 20 : 32),
                    header,
                    SizedBox(height: w < 360 ? 28 : 40),
                    actions,
                  ],
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: math.max(0.0, constraints.maxHeight - 32)),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: content,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.muted,
    required this.large,
  });

  final String title;
  final String subtitle;
  final Color titleColor;
  final Color? muted;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = large ? theme.textTheme.displaySmall : theme.textTheme.headlineMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: base?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: large ? -0.9 : -0.6,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(color: muted, height: 1.55),
        ),
      ],
    );
  }
}

/// Decorative hero mark: a rounded gradient tile over a soft glow, with two
/// small floating chips. Purely visual, so hidden from semantics.
class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.gradient, this.size = 96});

  final List<Color> gradient;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = size * 1.55;

    Widget chip(IconData icon) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: BlueColors.seed.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: theme.colorScheme.primary),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: total,
        height: total,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: total,
              height: total,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [gradient.first.withValues(alpha: 0.16), Colors.transparent],
                ),
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.cloud_sync_rounded, color: Colors.white, size: size * 0.42),
            ),
            Positioned(
              top: total * 0.08,
              right: total * 0.06,
              child: chip(Icons.verified_user_rounded),
            ),
            Positioned(
              bottom: total * 0.10,
              left: total * 0.04,
              child: chip(Icons.sync_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

/// Signed-in state: gradient-ringed avatar with a "connected" badge, name and
/// email on a card surface so it reads as a confirmation, not a plain row.
class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.user,
    required this.muted,
    required this.gradient,
  });

  final dynamic user; // matches auth.currentUser's existing type
  final Color? muted;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null ? Icon(Icons.person_rounded, color: cs.primary) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName ?? context.l10n.googleUser,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.email!,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Google's brand guidelines call for a neutral (not tinted) button, so this
/// stays a surface-colored outlined button rather than the blue gradient —
/// a third-party sign-in should read as distinct from the app's own actions.
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BlueColors.seed.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: cs.primary),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.login_rounded, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}