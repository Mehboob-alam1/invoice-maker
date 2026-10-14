import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/blue_theme.dart';
import '../core/utils/currency_format.dart';
import '../l10n/app_strings.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';

/// Home summary. Free sees the current month. Pro can pick a range and export CSV.
class InvoiceDashboard extends StatefulWidget {
  const InvoiceDashboard({super.key, required this.provider});

  final InvoiceProvider provider;

  @override
  State<InvoiceDashboard> createState() => _InvoiceDashboardState();
}

class _InvoiceDashboardState extends State<InvoiceDashboard> {
  DateTime? _from;
  DateTime? _to;
  String? _currency;

  bool get _pro => widget.provider.isPro;

  List<Invoice> get _invoices {
    final all = widget.provider.invoices.where((invoice) => !invoice.isEstimate);
    final now = DateTime.now();
    final from = _pro ? _from : DateTime(now.year, now.month);
    final to = _pro ? _to : DateTime(now.year, now.month + 1, 0, 23, 59);
    return all.where((invoice) {
      if (from != null && invoice.date.isBefore(DateTime(from.year, from.month, from.day))) return false;
      if (to != null && invoice.date.isAfter(DateTime(to.year, to.month, to.day, 23, 59))) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final invoices = _invoices;
    final codes = invoices.map((invoice) => invoice.currency).toSet().toList()..sort();
    final currency = codes.contains(_currency) ? _currency! : (codes.isEmpty ? 'USD' : codes.first);
    final scoped = invoices.where((invoice) => invoice.currency == currency).toList();
    final unpaid = scoped
        .where((invoice) => invoice.displayStatus != InvoiceStatus.paid)
        .fold<double>(0, (sum, invoice) => sum + invoice.balanceDue);
    final overdue = scoped
        .where((invoice) => invoice.displayStatus == InvoiceStatus.overdue)
        .fold<double>(0, (sum, invoice) => sum + invoice.balanceDue);
    final paid = scoped
        .where((invoice) => invoice.displayStatus == InvoiceStatus.paid)
        .fold<double>(0, (sum, invoice) => sum + invoice.total);
    final clients = <String, double>{};
    for (final invoice in scoped) {
      clients[invoice.client.name] = (clients[invoice.client.name] ?? 0) + invoice.total;
    }
    final top = clients.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _pro ? strings.allTime : strings.thisMonth,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (codes.length > 1)
                  DropdownButton<String>(
                    value: currency,
                    items: codes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                    onChanged: (value) => setState(() => _currency = value),
                  ),
                if (_pro)
                  TextButton(onPressed: () => _export(scoped), child: Text(strings.exportCsv)),
              ],
            ),
            if (_pro)
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text(_from == null ? strings.repeatStart : DateFormat.yMMMd().format(_from!)),
                    onPressed: () => _pick(start: true),
                  ),
                  ActionChip(
                    label: Text(_to == null ? strings.repeatUntil : DateFormat.yMMMd().format(_to!)),
                    onPressed: () => _pick(start: false),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _stat(strings.unpaidTotal, currency, unpaid),
                _stat(strings.overdueAmount, currency, overdue),
                _stat(strings.paidThisMonth, currency, paid),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(height: 72, child: _Bars(invoices: widget.provider.invoices, currency: currency)),
            if (top.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(strings.topClients, style: theme.textTheme.labelMedium),
              for (final entry in top.take(3))
                Text('${entry.key} · ${CurrencyFormat.format(currency, entry.value)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String currency, double value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            CurrencyFormat.format(currency, value),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Future<void> _pick({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _export(List<Invoice> invoices) async {
    final buffer = StringBuffer('number,client,date,currency,status,total,balance\n');
    for (final invoice in invoices) {
      buffer.writeln([
        _cell(invoice.number),
        _cell(invoice.client.name),
        invoice.date.toIso8601String(),
        invoice.currency,
        invoice.displayStatus.name,
        invoice.total.toStringAsFixed(2),
        invoice.balanceDue.toStringAsFixed(2),
      ].join(','));
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(buffer.toString().codeUnits),
            mimeType: 'text/csv',
            name: 'invoices.csv',
          ),
        ],
      ),
    );
  }

  String _cell(String value) => '"${value.replaceAll('"', '""')}"';
}

class _Bars extends StatelessWidget {
  const _Bars({required this.invoices, required this.currency});

  final List<Invoice> invoices;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final month = DateTime(now.year, now.month - (5 - index));
      final total = invoices
          .where((invoice) =>
              !invoice.isEstimate &&
              invoice.currency == currency &&
              invoice.date.year == month.year &&
              invoice.date.month == month.month)
          .fold<double>(0, (sum, invoice) => sum + invoice.total);
      return (label: DateFormat.MMM().format(month), total: total);
    });
    final max = months.fold<double>(0, (peak, month) => month.total > peak ? month.total : peak);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final month in months)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: max <= 0 ? 0.05 : (month.total / max).clamp(0.05, 1),
                        widthFactor: 1,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: BlueColors.bright,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(month.label, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
