import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/blue_theme.dart';
import '../l10n/app_strings.dart';

/// Combined star rating + optional feedback — opens Play review for high ratings.
Future<void> showRateFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Theme(
      data: buildBlueTheme(Theme.of(ctx)),
      child: const _RateFeedbackSheet(),
    ),
  );
}

class _RateFeedbackSheet extends StatefulWidget {
  const _RateFeedbackSheet();

  @override
  State<_RateFeedbackSheet> createState() => _RateFeedbackSheetState();
}

class _RateFeedbackSheetState extends State<_RateFeedbackSheet> {
  int _stars = 0;
  final _comment = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars < 1) return;
    setState(() => _submitting = true);
    final strings = AppStrings.read(context);
    final rating = _stars;
    final text = _comment.text.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_app_rating_stars', rating);
      await prefs.setString('last_app_feedback', text);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('app_feedback').add({
        'stars': rating,
        'comment': text,
        'uid': uid,
        'platform': 'android',
        'packageId': AppConfig.androidPackageId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (rating >= 4) {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        } else {
          final uri = Uri.parse(AppConfig.playStoreUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      } else if (text.isNotEmpty) {
        final mail = Uri(
          scheme: 'mailto',
          path: AppConfig.supportEmail,
          queryParameters: {
            'subject': '${AppConfig.appDisplayName} feedback ($rating★)',
            'body': text,
          },
        );
        if (await canLaunchUrl(mail)) {
          await launchUrl(mail);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.thanksFeedback)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? theme.colorScheme.onSurface : BlueColors.navy;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.rateUsTitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            strings.rateUsCombinedSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.extension<AppSemanticColors>()?.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return IconButton(
                onPressed: _submitting ? null : () => setState(() => _stars = i + 1),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? Colors.amber.shade600 : theme.dividerColor,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 4,
            enabled: !_submitting,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: strings.feedbackOptionalLabel,
              hintText: strings.feedbackHint,
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          BlueGradientButton(
            label: strings.submitRating,
            icon: null,
            loading: _submitting,
            onPressed: _submitting || _stars < 1 ? null : _submit,
          ),
        ],
      ),
    );
  }
}
