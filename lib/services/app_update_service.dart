import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../core/constants/app_config.dart';
import '../core/remote_config/remote_config_repository.dart';
import '../l10n/app_strings.dart';

/// Asks for a Play in-app update after a newer version is published.
class AppUpdateService {
  AppUpdateService._();

  static bool _checked = false;

  static Future<void> promptIfAvailable(BuildContext context) async {
    if (!Platform.isAndroid || _checked) return;
    _checked = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!context.mounted) return;

      if (info.installStatus == InstallStatus.downloaded) {
        await _askToRestart(context);
        return;
      }

      final inProgress =
          info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress;
      final available = info.updateAvailability == UpdateAvailability.updateAvailable;
      if (!inProgress && !available) return;

      final force = RemoteConfigRepository.instance.minSupportedVersion > AppConfig.buildNumber;
      if (force && (inProgress || available)) {
        try {
          await InAppUpdate.performImmediateUpdate();
          return;
        } catch (error) {
          debugPrint('Immediate update failed: $error');
        }
      }

      if (inProgress || info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (!info.flexibleUpdateAllowed) return;
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success && context.mounted) {
        await _askToRestart(context);
      }
    } catch (e, st) {
      debugPrint('In-app update skipped: $e\n$st');
    }
  }

  static Future<void> _askToRestart(BuildContext context) async {
    final restart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final strings = ctx.l10n;
        final theme = Theme.of(ctx);
        return AlertDialog(
          icon: Icon(Icons.system_update_rounded, color: theme.colorScheme.primary, size: 36),
          title: Text(strings.updateReadyTitle),
          content: Text(strings.updateReadyBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(strings.notNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(strings.restartApp),
            ),
          ],
        );
      },
    );
    if (restart == true) {
      await InAppUpdate.completeFlexibleUpdate();
    }
  }
}
