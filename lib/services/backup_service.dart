import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../providers/invoice_provider.dart';
import 'auth_service.dart';
import 'home_widget_bridge.dart';
import 'user_database_service.dart';

/// Manual backup for everyone, weekly Wi-Fi backup for Pro. Stored in Supabase.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _lastKey = 'backup_last_at';
  static const _maxImageBytes = 400000;
  static const _maxPayloadBytes = 1500000;

  Future<DateTime?> lastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastKey);
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> maybeAutoBackup(InvoiceProvider provider) async {
    if (!provider.isPro) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    if (!UserDatabaseService.instance.isReady) return;
    final last = await lastBackupAt();
    if (last != null && DateTime.now().difference(last).inDays < 7) return;
    if (!await HomeWidgetBridge.isOnWifi()) return;
    final result = await _upload(provider, user, AppStrings('en'));
    if (!result.ok) debugPrint('Auto backup skipped: ${result.message}');
  }

  Future<void> showSheet(BuildContext context) async {
    final signedIn = await _ensureGoogle(context);
    if (!signedIn || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => const _BackupSheet(),
    );
  }

  Future<bool> _ensureGoogle(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) return true;
    final strings = AppStrings.read(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.backupSignInTitle),
        content: Text(strings.backupSignInBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.signInWithGoogle)),
        ],
      ),
    );
    if (go != true || !context.mounted) return false;
    final auth = context.read<AuthService>();
    final ok = await auth.signInWithGoogle();
    if (!context.mounted) return false;
    final signedIn = ok && FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.isAnonymous;
    if (signedIn) return true;
    final detail = auth.lastError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(detail ?? strings.backupSignInCancelled)),
    );
    return false;
  }

  Future<_BackupOutcome> _upload(InvoiceProvider provider, User user, AppStrings strings) async {
    if (!UserDatabaseService.instance.isReady) {
      return _BackupOutcome.fail(strings.backupFailed);
    }
    try {
      await user.getIdToken(true);
      final map = provider.backupSnapshot();
      if (_isEmpty(map)) return _BackupOutcome.fail(strings.backupEmpty);

      var imagesSkipped = false;
      final logo = await _encodeFile(provider.businessLogoPath);
      final signature = await _encodeFile(provider.signaturePath);
      final stamp = await _encodeFile(provider.stampPath);
      imagesSkipped = logo.skipped || signature.skipped || stamp.skipped;
      map['logoBase64'] = logo.data;
      map['signatureBase64'] = signature.data;
      map['stampBase64'] = stamp.data;

      if (_encodedSize(map) > _maxPayloadBytes) {
        map.remove('logoBase64');
        map.remove('signatureBase64');
        map.remove('stampBase64');
        imagesSkipped = true;
      }
      if (_encodedSize(map) > _maxPayloadBytes) {
        return _BackupOutcome.fail(strings.backupTooLarge);
      }

      await UserDatabaseService.instance.saveBackup(
        uid: user.uid,
        email: user.email,
        payload: map,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastKey, DateTime.now().millisecondsSinceEpoch);
      return _BackupOutcome.ok(imagesSkipped ? strings.backupImagesSkipped : strings.backupDone);
    } catch (error, stack) {
      debugPrint('Backup upload failed: $error\n$stack');
      return _BackupOutcome.fail(_messageFor(error, strings, restore: false));
    }
  }

  Future<_BackupOutcome> _restore(InvoiceProvider provider, AppStrings strings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !UserDatabaseService.instance.isReady) {
      return _BackupOutcome.fail(strings.backupRestoreFailed);
    }
    try {
      await user.getIdToken(true);
      final payload = await UserDatabaseService.instance.fetchBackup(user.uid);
      if (payload == null) return _BackupOutcome.fail(strings.backupNone);
      if (payload['invoices'] is! List || payload['clients'] is! List) {
        return _BackupOutcome.fail(strings.backupDamaged);
      }
      final logo = await _writeFile(payload.remove('logoBase64')?.toString(), 'business_logo.png');
      final signature = await _writeFile(payload.remove('signatureBase64')?.toString(), 'business_signature.png');
      final stamp = await _writeFile(payload.remove('stampBase64')?.toString(), 'business_stamp.png');
      if (logo != null) payload['businessLogoPath'] = logo;
      if (signature != null) payload['signaturePath'] = signature;
      if (stamp != null) payload['stampPath'] = stamp;
      await provider.restoreBackupPayload(payload);
      return _BackupOutcome.ok(strings.backupRestored);
    } catch (error, stack) {
      debugPrint('Backup restore failed: $error\n$stack');
      return _BackupOutcome.fail(_messageFor(error, strings, restore: true));
    }
  }

  bool _isEmpty(Map<String, dynamic> map) {
    final invoices = map['invoices'];
    final clients = map['clients'];
    final items = map['catalogItems'];
    final name = map['businessName']?.toString().trim() ?? '';
    return name.isEmpty &&
        invoices is List &&
        invoices.isEmpty &&
        clients is List &&
        clients.isEmpty &&
        items is List &&
        items.isEmpty;
  }

  int _encodedSize(Map<String, dynamic> map) => utf8.encode(jsonEncode(map)).length;

  String _messageFor(Object error, AppStrings strings, {required bool restore}) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network') ||
        raw.contains('connection abort') ||
        raw.contains('timed out')) {
      return strings.backupOffline;
    }
    if (raw.contains('42501') ||
        raw.contains('jwt') ||
        raw.contains('permission') ||
        raw.contains('row-level') ||
        raw.contains('not authenticated')) {
      return strings.backupSignInAgain;
    }
    if (raw.contains('413') || raw.contains('payload too large') || raw.contains('entity too large')) {
      return strings.backupTooLarge;
    }
    return restore ? strings.backupRestoreFailed : strings.backupFailed;
  }

  Future<_EncodedFile> _encodeFile(String path) async {
    if (path.isEmpty) return const _EncodedFile();
    final file = File(path);
    if (!await file.exists()) return const _EncodedFile();
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxImageBytes) return const _EncodedFile(skipped: true);
    return _EncodedFile(data: base64Encode(bytes));
  }

  Future<String?> _writeFile(String? encoded, String name) async {
    if (encoded == null || encoded.isEmpty) return null;
    final bytes = base64Decode(encoded);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

class _BackupOutcome {
  const _BackupOutcome._(this.ok, this.message);
  final bool ok;
  final String message;

  factory _BackupOutcome.ok(String message) => _BackupOutcome._(true, message);
  factory _BackupOutcome.fail(String message) => _BackupOutcome._(false, message);
}

class _EncodedFile {
  const _EncodedFile({this.data, this.skipped = false});
  final String? data;
  final bool skipped;
}

class _BackupSheet extends StatefulWidget {
  const _BackupSheet();

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  DateTime? _last;
  bool _busy = false;
  String? _status;
  bool _statusOk = false;
  bool _uploadBusy = false;

  @override
  void initState() {
    super.initState();
    BackupService.instance.lastBackupAt().then((value) {
      if (mounted) setState(() => _last = value);
    });
  }

  Future<void> _runUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    final strings = context.l10n;
    if (user == null) {
      setState(() {
        _statusOk = false;
        _status = strings.backupSignInAgain;
      });
      return;
    }
    setState(() {
      _busy = true;
      _uploadBusy = true;
      _statusOk = true;
      _status = strings.backupSaving;
    });
    final provider = context.read<InvoiceProvider>();
    final result = await BackupService.instance._upload(provider, user, strings);
    if (!mounted) return;
    final last = result.ok ? await BackupService.instance.lastBackupAt() : _last;
    if (!mounted) return;
    setState(() {
      _busy = false;
      _uploadBusy = false;
      _last = last;
      _statusOk = result.ok;
      _status = result.message;
    });
  }

  Future<void> _runRestore() async {
    final strings = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.backupRestoreTitle),
        content: Text(strings.backupRestoreBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.backupRestore)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _uploadBusy = false;
      _statusOk = true;
      _status = strings.backupRestoring;
    });
    final provider = context.read<InvoiceProvider>();
    final result = await BackupService.instance._restore(provider, strings);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusOk = result.ok;
      _status = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final provider = context.watch<InvoiceProvider>();
    final when = _last == null ? strings.backupNever : DateFormat.yMMMd().add_jm().format(_last!);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.backupTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(strings.backupLast(when)),
          const SizedBox(height: 4),
          Text(provider.isPro ? strings.backupProHint : strings.backupFreeHint),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Material(
              color: (_statusOk ? scheme.primary : scheme.error).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _statusOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _statusOk ? scheme.primary : scheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_status!)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _runUpload,
            child: _busy && _uploadBusy
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(strings.backupSaving),
                    ],
                  )
                : Text(strings.backupNow),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _runRestore,
            child: _busy && !_uploadBusy
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(strings.backupRestoring),
                    ],
                  )
                : Text(strings.backupRestore),
          ),
        ],
      ),
    );
  }
}
