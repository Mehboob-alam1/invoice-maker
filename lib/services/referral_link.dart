import '../core/constants/app_config.dart';

/// Play Store invite link and install-referrer parsing.
class ReferralLink {
  ReferralLink._();

  static final _codePattern = RegExp(r'^[A-Z2-9]{6,8}$');

  static String? normalizeCode(String? raw) {
    if (raw == null) return null;
    final code = raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (!_codePattern.hasMatch(code)) return null;
    if (code.contains('0') || code.contains('O') || code.contains('1') || code.contains('I')) {
      return null;
    }
    return code;
  }

  static String shareUrl(String code) {
    final referrer = Uri.encodeComponent('utm_source=referral&utm_medium=invite&utm_content=$code');
    return '${AppConfig.playStoreUrl}&referrer=$referrer';
  }

  /// Reads `utm_content` from a Play install referrer string.
  static String? codeFromInstallReferrer(String? referrer) {
    if (referrer == null || referrer.trim().isEmpty) return null;
    final params = Uri.splitQueryString(referrer);
    return normalizeCode(params['utm_content']);
  }
}
