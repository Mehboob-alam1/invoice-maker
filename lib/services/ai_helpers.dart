import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency_format.dart';
import '../l10n/app_strings.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import 'invoice_create_gate.dart';

/// Small AI actions on the same credit check the invoice generator already uses.
class AiHelpers {
  AiHelpers._();

  static Future<String?> politeReminder(BuildContext context, Invoice invoice) async {
    final input = '${invoice.client.name} ${invoice.number}';
    if (!await _spend(context, input)) return null;
    if (!context.mounted) return null;
    final provider = context.read<InvoiceProvider>();
    final amount = CurrencyFormat.format(
      invoice.currency,
      invoice.balanceDue > 0.009 ? invoice.balanceDue : invoice.total,
    );
    final due = invoice.dueDate == null
        ? ''
        : DateFormat.yMMMd(provider.languageCode).format(invoice.dueDate!);
    return AppStrings.read(context).politeReminder(
      client: invoice.client.name,
      number: invoice.number,
      amount: amount,
      due: due.isEmpty ? AppStrings.read(context).dueDate : due,
    );
  }

  static Future<String?> improveDescription(BuildContext context, String raw) async {
    if (!await _spend(context, raw.trim().isEmpty ? 'item' : raw)) return null;
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return null;
    final sentence = cleaned[0].toUpperCase() + cleaned.substring(1);
    return sentence.endsWith('.') ? sentence : '$sentence.';
  }

  static Future<({int dueDays, String notes})?> suggestDueAndNotes(
    BuildContext context,
    String? clientId,
  ) async {
    final provider = context.read<InvoiceProvider>();
    final memory = clientId == null ? null : provider.memoryForClient(clientId);
    if (!await _spend(context, clientId ?? 'suggest')) return null;
    if (memory != null && (memory.notes.isNotEmpty || memory.dueDays > 0)) {
      return (dueDays: memory.dueDays, notes: memory.notes);
    }
    if (!context.mounted) return null;
    return (dueDays: 14, notes: AppStrings.read(context).suggestedNotes);
  }

  static Future<bool> _spend(BuildContext context, String input) async {
    if (!await ensureAiGenerationAllowed(context, inputText: input)) return false;
    if (!context.mounted) return false;
    context.read<InvoiceProvider>().recordAiTokenUsage(
      InvoiceProvider.estimateAiTokensForInput(input),
    );
    return true;
  }
}
