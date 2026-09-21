import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice_item.dart';
import '../../providers/invoice_provider.dart';

class CreateWithAiScreen extends StatefulWidget {
  const CreateWithAiScreen({super.key});

  @override
  State<CreateWithAiScreen> createState() => _CreateWithAiScreenState();
}

class _CreateWithAiScreenState extends State<CreateWithAiScreen> {
  final _clientController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _generating = false;

  @override
  void dispose() {
    _clientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<InvoiceItem> _itemsFromDescription(String raw, String fallback) {
    final lines = raw.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) {
      return [
        InvoiceItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          description: fallback,
          unitCost: 100,
          quantity: 1,
        ),
      ];
    }
    final money = RegExp(r'(\d+(?:\.\d{1,2})?)');
    final items = <InvoiceItem>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final matches = money.allMatches(line).toList();
      final match = matches.isEmpty ? null : matches.last;
      final amount = match == null ? 100.0 : double.tryParse(match.group(1)!) ?? 100;
      var description = match == null ? line : line.substring(0, match.start).trim();
      description = description.replaceAll(RegExp(r'[\s$€£]+$'), '');
      items.add(
        InvoiceItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          description: description.isEmpty ? line : description,
          unitCost: amount,
          quantity: 1,
        ),
      );
    }
    return items;
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final strings = AppStrings.read(context);
    final provider = context.read<InvoiceProvider>();
    final clientName =
        _clientController.text.trim().isEmpty ? strings.newClientFallback : _clientController.text.trim();
    final client = provider.findOrCreateClient(name: clientName);
    provider.createInvoice(
      client: client,
      items: _itemsFromDescription(_descriptionController.text, strings.serviceThisMonth),
    );

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(strings.createWithAi)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.aiIntro,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Text(strings.clientNameOptional, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _clientController,
              decoration: InputDecoration(
                hintText: strings.clientNameHintAi,
                prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Text(strings.writeInvoiceDetail, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(hintText: strings.invoiceThisMonthHint),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_generating ? strings.generating : strings.generateInvoice),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                strings.aiFillHint,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
