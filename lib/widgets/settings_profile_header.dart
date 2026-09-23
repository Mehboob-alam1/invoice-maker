import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_texts.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../ads/ad_action.dart';
import '../navigation/app_page_route.dart';
import '../providers/invoice_provider.dart';
import '../screens/business_setup/edit_business_screen.dart';
import '../services/auth_service.dart';

/// Single account card: Google sign-in + company name (no duplicate profile blocks).
class SettingsProfileHeader extends StatefulWidget {
  const SettingsProfileHeader({super.key});

  @override
  State<SettingsProfileHeader> createState() => _SettingsProfileHeaderState();
}

class _SettingsProfileHeaderState extends State<SettingsProfileHeader> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocus;
  var _syncedName = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _syncFromProvider(String businessName) {
    if (_nameFocus.hasFocus) return;
    if (_nameController.text == businessName) return;
    _nameController.text = businessName;
    _syncedName = businessName;
  }

  void _saveName() {
    final trimmed = _nameController.text.trim();
    final value = trimmed.isEmpty ? AppTexts.defaultBusinessName : trimmed;
    if (value == _syncedName) return;
    context.read<InvoiceProvider>().setBusinessProfile(name: value);
    _syncedName = value;
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final auth = context.read<AuthService>();
    final ok = await auth.signInWithGoogle();
    if (!context.mounted) return;
    if (!ok && auth.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.lastError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = context.l10n;
    final provider = context.watch<InvoiceProvider>();
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    final displayName = provider.businessName.isEmpty ? AppTexts.defaultBusinessName : provider.businessName;
    _syncFromProvider(displayName);

    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B';
    final subtitle = user?.email ?? (provider.businessEmail.isNotEmpty ? provider.businessEmail : null);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? Text(
                          avatarLetter,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null)
                        Text(
                          user.displayName ?? strings.googleUser,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          strings.accountNotSignedIn,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: muted),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        strings.googleAccountPhotoHint,
                        style: theme.textTheme.labelSmall?.copyWith(color: muted, fontSize: 11),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (user != null)
                  IconButton(
                    tooltip: strings.signOut,
                    onPressed: auth.signingIn ? null : () => auth.signOut(),
                    icon: const Icon(Icons.logout_rounded),
                  )
                else if (auth.signingIn)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => _signInWithGoogle(context),
                    child: Text(strings.signIn),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              strings.settingsBusinessNameLabel,
              style: theme.textTheme.labelMedium?.copyWith(color: muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              textCapitalization: TextCapitalization.words,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                isDense: true,
                hintText: strings.businessNameHint,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixIcon: IconButton(
                  tooltip: strings.save,
                  icon: const Icon(Icons.check_rounded),
                  onPressed: _saveName,
                ),
              ),
              onSubmitted: (_) => _saveName(),
              onTapOutside: (_) => _saveName(),
            ),
            const SizedBox(height: 8),
            Text(
              strings.companyLogoComingSoon,
              style: theme.textTheme.bodySmall?.copyWith(color: muted, fontStyle: FontStyle.italic),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.storefront_outlined, color: theme.colorScheme.primary),
              title: Text(strings.manageBusiness, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(strings.editProfileDetails, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              trailing: Icon(Icons.chevron_right_rounded, color: muted),
              onTap: () => runWithInterstitial(context, () {
                Navigator.push(context, appPageRoute(const EditBusinessScreen()));
              }),
            ),
          ],
        ),
      ),
    );
  }
}
