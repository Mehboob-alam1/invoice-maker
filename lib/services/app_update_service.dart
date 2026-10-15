import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../core/constants/app_config.dart';
import '../l10n/app_strings.dart';
import '../core/remote_config/remote_config_repository.dart';
import '../widgets/app_dialog.dart';

/// Play in-app updates. A required build updates immediately. Everything else
/// asks first, downloads in the background, then asks to restart.
class AppUpdateService {
  AppUpdateService._();

  static bool _checked = false;
  static StreamSubscription<InstallStatus>? _installSub;

  /// Once per launch, after the first screen is visible.
  static Future<void> promptIfAvailable(BuildContext context) async {
    if (!Platform.isAndroid || _checked) return;
    _checked = true;
    await _check(context, tellIfCurrent: false);
  }

  /// Settings. Always checks, and says so when nothing is waiting.
  static Future<void> checkFromSettings(BuildContext context) async {
    if (!Platform.isAndroid) return;
    await _check(context, tellIfCurrent: true);
  }

  static Future<void> _check(
    BuildContext context, {
    required bool tellIfCurrent,
  }) async {
    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (error) {
      debugPrint('In-app update check failed: $error');
      if (tellIfCurrent && context.mounted) {
        await _message(
          context,
          icon: Icons.cloud_off_rounded,
          title: context.l10n.updateCheckFailedTitle,
          message: context.l10n.updateCheckFailedBody,
        );
      }
      return;
    }
    if (!context.mounted) return;

    if (info.installStatus == InstallStatus.downloaded) {
      await _askToRestart(context);
      return;
    }

    final available = info.updateAvailability == UpdateAvailability.updateAvailable;
    if (!available) {
      if (tellIfCurrent) {
        await _message(
          context,
          icon: Icons.check_circle_rounded,
          tone: AppDialogTone.success,
          title: context.l10n.upToDateTitle,
          message: context.l10n.upToDateBody,
        );
      }
      return;
    }

    final force = RemoteConfigRepository.instance.minSupportedVersion > AppConfig.buildNumber;
    final strings = context.l10n;
    final start = await showDialog<bool>(
      context: context,
      barrierDismissible: !force,
      builder: (dialogContext) => AppDialog(
        tone: force ? AppDialogTone.warning : AppDialogTone.primary,
        icon: Icons.system_update_rounded,
        title: strings.updateAvailableTitle,
        message: strings.updateAvailableBody,
        actions: [
          AppDialogAction(
            label: strings.updateNow,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
          if (!force)
            AppDialogAction(
              label: strings.notNow,
              style: AppDialogActionStyle.text,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
        ],
      ),
    );
    if (start != true || !context.mounted) return;

    try {
      if (force || !info.flexibleUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
      await InAppUpdate.startFlexibleUpdate();
      if (!context.mounted) return;
      _listenForDownload(context);
    } catch (error) {
      debugPrint('In-app update failed: $error');
      if (tellIfCurrent && context.mounted) {
        await _message(
          context,
          icon: Icons.cloud_off_rounded,
          title: context.l10n.updateCheckFailedTitle,
          message: context.l10n.updateCheckFailedBody,
        );
      }
    }
  }

  static void _listenForDownload(BuildContext context) {
    _installSub?.cancel();
    _installSub = InAppUpdate.installUpdateListener.listen((status) {
      if (status != InstallStatus.downloaded) return;
      _installSub?.cancel();
      _installSub = null;
      if (!context.mounted) return;
      _askToRestart(context);
    });
  }

  static Future<void> _askToRestart(BuildContext context) async {
    if (!context.mounted) return;
    final strings = context.l10n;
    final restart = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        tone: AppDialogTone.success,
        icon: Icons.download_done_rounded,
        title: strings.updateReadyTitle,
        message: strings.updateReadyBody,
        actions: [
          AppDialogAction(
            label: strings.restartApp,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
          AppDialogAction(
            label: strings.notNow,
            style: AppDialogActionStyle.text,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
        ],
      ),
    );
    if (restart == true) {
      await InAppUpdate.completeFlexibleUpdate();
    }
  }

  static Future<void> _message(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    AppDialogTone tone = AppDialogTone.primary,
  }) {
    final strings = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        tone: tone,
        icon: icon,
        title: title,
        message: message,
        actions: [
          AppDialogAction(
            label: strings.ok,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }
}
