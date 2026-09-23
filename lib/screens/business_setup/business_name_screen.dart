import 'package:flutter/material.dart';

import '../../navigation/app_page_route.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_texts.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/invoice_provider.dart';
import '../home/invoices_home_screen.dart';

class BusinessNameScreen extends StatefulWidget {
  const BusinessNameScreen({super.key});

  @override
  State<BusinessNameScreen> createState() => _BusinessNameScreenState();
}

class _BusinessNameScreenState extends State<BusinessNameScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final provider = context.read<InvoiceProvider>();
    final name = _controller.text.trim().isEmpty ? AppTexts.defaultBusinessName : _controller.text.trim();
    provider.setBusinessName(name);
    Navigator.of(context).pushReplacement(
      appPageRoute(const InvoicesHomeScreen(), adScopeKey: 'home'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.businessNameTitle,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(labelText: strings.businessNameHint),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 12),
              Text(
                strings.businessNameHelp,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const Spacer(),
              ElevatedButton(onPressed: _continue, child: Text(strings.continueLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
