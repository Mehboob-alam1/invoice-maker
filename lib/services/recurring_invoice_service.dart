import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import 'invoice_reminder_service.dart';

/// Creates due repeating invoices the next time the app is open, then notifies.
class RecurringInvoiceService {
  RecurringInvoiceService._();
  static final RecurringInvoiceService instance = RecurringInvoiceService._();

  Future<void> catchUp(InvoiceProvider provider) async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final sources = provider.invoices.where((invoice) => invoice.recurrenceActive).toList();
    for (final source in sources) {
      var guard = 0;
      while (guard < 12) {
        final current = provider.invoiceById(source.id);
        final next = current?.nextOccurrence;
        if (current == null || next == null || !current.recurrenceActive) break;
        final due = DateTime(next.year, next.month, next.day);
        if (due.isAfter(day)) break;
        if (current.recurrenceEnd != null) {
          final end = DateTime(
            current.recurrenceEnd!.year,
            current.recurrenceEnd!.month,
            current.recurrenceEnd!.day,
          );
          if (due.isAfter(end)) {
            provider.updateInvoice(current.copyWith(recurrenceActive: false));
            break;
          }
        }
        final copy = await provider.spawnRecurringCopy(current);
        if (copy != null) {
          final period = switch (current.recurrence) {
            Recurrence.weekly => 'weekly',
            Recurrence.monthly => 'monthly',
            _ => 'scheduled',
          };
          await InvoiceReminderService.instance.showReady(
            invoiceId: copy.id,
            client: copy.client.name,
            period: period,
          );
        }
        guard++;
      }
    }
  }
}
