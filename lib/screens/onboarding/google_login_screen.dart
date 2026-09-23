import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/app_page_route.dart';
import '../../providers/invoice_provider.dart';
import '../../services/auth_service.dart';
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
    final theme = Theme.of(context);
    final strings = context.l10n;
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final gradient = theme.extension<AppSemanticColors>()?.heroGradient ??
        [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _HeroBadge(gradient: gradient),
              const SizedBox(height: 36),
              Text(
                strings.googleLoginTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.googleLoginSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(color: muted, height: 1.5),
              ),
              const Spacer(),
              if (user != null) ...[
                _SignedInCard(user: user, muted: muted),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _continue(context),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(strings.continueLabel),
                ),
              ] else ...[
                _GoogleSignInButton(
                  loading: auth.signingIn,
                  label: strings.signInWithGoogle,
                  onPressed: auth.signingIn ? null : () => _signIn(context),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: auth.signingIn ? null : () => _continue(context),
                  style: TextButton.styleFrom(foregroundColor: muted),
                  child: Text(strings.skipGoogleLogin),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decorative hero mark: a soft radial glow behind the sync icon, instead of a
/// flat rounded rectangle — gives the top of the screen some depth without
/// introducing any new colors outside the app's existing gradient token.
class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.gradient});

  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      width: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 148,
            width: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [gradient.first.withValues(alpha: 0.16), Colors.transparent],
              ),
            ),
          ),
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
            child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}

/// Signed-in state: avatar with a small "connected" badge, name/email, laid
/// out on a subtly tinted surface so it reads as a confirmation, not a plain row.
class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user, required this.muted});

  final dynamic user; // matches auth.currentUser's existing type
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, size: 18, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? context.l10n.googleUser,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

/// Google's own brand guidelines call for a neutral (not tinted) button with
/// clear affordance — kept close to that standard rather than styled to
/// match the app's primary color, since a third-party sign-in button should
/// read as distinct from the app's own actions.
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
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onSurface,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}