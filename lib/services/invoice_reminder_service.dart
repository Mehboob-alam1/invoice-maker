import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/app_texts.dart';
import '../core/utils/currency_format.dart';
import '../models/invoice.dart';

/// Local due-date reminders. Free: due date only. Pro: 3 days before, due date, +3, +7.
class InvoiceReminderService {
  InvoiceReminderService._();
  static final InvoiceReminderService instance = InvoiceReminderService._();

  static const _hourKey = 'invoice_reminder_hour';
  static const _minuteKey = 'invoice_reminder_minute';
  static const _messageKey = 'invoice_reminder_message';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? pendingInvoiceId;

  Future<void> prepare() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          pendingInvoiceId = response.payload;
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true && payload != null && payload.isNotEmpty) {
        pendingInvoiceId = payload;
      }
      _ready = true;
    } catch (error) {
      debugPrint('InvoiceReminderService.prepare: $error');
    }
  }

  Future<({int hour, int minute, String message})> settings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      hour: prefs.getInt(_hourKey) ?? 9,
      minute: prefs.getInt(_minuteKey) ?? 0,
      message: prefs.getString(_messageKey) ?? '',
    );
  }

  Future<void> saveSettings({required int hour, required int minute, required String message}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
    await prefs.setString(_messageKey, message.trim());
  }

  /// Runs after due-date reminders are rewritten, so other local campaigns survive `cancelAll`.
  Future<void> Function()? afterSync;

  String? takePending() {
    final id = pendingInvoiceId;
    pendingInvoiceId = null;
    return id;
  }

  Future<void> sync(List<Invoice> invoices, {required bool pro}) async {
    if (!_ready) await prepare();
    if (!_ready) return;
    try {
      await _plugin.cancelAllPendingNotifications();
      final stored = await SharedPreferences.getInstance();
      final allowReminders = stored.getBool('engagement_ch_reminders') ?? true;
      if (allowReminders) {
        final prefs = await settings();
        for (final invoice in invoices) {
          if (invoice.isEstimate || invoice.displayStatus == InvoiceStatus.paid) continue;
          final due = invoice.dueDate;
          if (due == null) continue;
          final offsets = pro ? const [-3, 0, 3, 7] : const [0];
          for (var i = 0; i < offsets.length; i++) {
            final when = _atTime(due.add(Duration(days: offsets[i])), prefs.hour, prefs.minute);
            if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
            await _plugin.zonedSchedule(
              id: _id(invoice.id, i),
              title: 'Invoice ${invoice.number}',
              body: _body(invoice, prefs.message),
              scheduledDate: when,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'invoice_due',
                  'Invoice reminders',
                  channelDescription: 'Reminders before and after an invoice due date',
                  importance: Importance.defaultImportance,
                  priority: Priority.defaultPriority,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: invoice.id,
            );
          }
        }
        for (final invoice in invoices) {
          if (!invoice.recurrenceActive || invoice.nextOccurrence == null) continue;
          final when = _atTime(invoice.nextOccurrence!, prefs.hour, prefs.minute);
          if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
          final period = switch (invoice.recurrence) {
            Recurrence.weekly => 'weekly',
            Recurrence.monthly => 'monthly',
            Recurrence.custom => 'scheduled',
            Recurrence.none => 'scheduled',
          };
          await _plugin.zonedSchedule(
            id: _id(invoice.id, 7),
            title: 'Invoice GO',
            body: AppTexts.recurringReady
                .replaceAll('{period}', period)
                .replaceAll('{client}', invoice.client.name),
            scheduledDate: when,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'invoice_due',
                'Invoice reminders',
                channelDescription: 'Reminders before and after an invoice due date',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: invoice.id,
          );
        }
      }
    } catch (error) {
      debugPrint('InvoiceReminderService.sync: $error');
    }
    try {
      await afterSync?.call();
    } catch (error) {
      debugPrint('InvoiceReminderService.afterSync: $error');
    }
  }

  Future<void> cancelCampaign(int id) async {
    if (!_ready) await prepare();
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (error) {
      debugPrint('InvoiceReminderService.cancelCampaign: $error');
    }
  }

  Future<void> scheduleCampaign({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    if (!_ready) await prepare();
    if (!_ready) return;
    final scheduled = tz.TZDateTime(tz.local, when.year, when.month, when.day, when.hour, when.minute);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (error) {
      debugPrint('InvoiceReminderService.scheduleCampaign: $error');
    }
  }

  Future<void> showReady({
    required String invoiceId,
    required String client,
    required String period,
  }) async {
    if (!_ready) await prepare();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _id(invoiceId, 6),
        title: 'Invoice GO',
        body: AppTexts.recurringReady
            .replaceAll('{period}', period)
            .replaceAll('{client}', client),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'invoice_due',
            'Invoice reminders',
            channelDescription: 'Reminders before and after an invoice due date',
          ),
        ),
        payload: invoiceId,
      );
    } catch (error) {
      debugPrint('InvoiceReminderService.showReady: $error');
    }
  }

  tz.TZDateTime _atTime(DateTime day, int hour, int minute) {
    return tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
  }

  String _body(Invoice invoice, String custom) {
    if (custom.trim().isNotEmpty) return custom.trim();
    final due = invoice.dueDate == null ? '' : '${invoice.dueDate!.year}-${invoice.dueDate!.month}-${invoice.dueDate!.day}';
    final amount = CurrencyFormat.format(
      invoice.currency,
      invoice.balanceDue > 0.009 ? invoice.balanceDue : invoice.total,
    );
    return AppTexts.invoiceReminderBody
        .replaceAll('{client}', invoice.client.name)
        .replaceAll('{number}', invoice.number)
        .replaceAll('{amount}', amount)
        .replaceAll('{due}', due)
        .replaceAll('{pay}', '');
  }

  int _id(String invoiceId, int slot) {
    var hash = 0;
    for (final code in invoiceId.codeUnits) {
      hash = (hash * 31 + code) & 0x0fffffff;
    }
    return hash * 4 + slot;
  }
}
