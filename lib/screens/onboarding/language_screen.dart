import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_languages.dart';
import '../../l10n/app_strings.dart';
import '../../providers/invoice_provider.dart';
import '../business_setup/business_name_screen.dart';

class LanguageScreen extends StatefulWidget {
  final bool fromOnboarding;

  const LanguageScreen({super.key, this.fromOnboarding = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = context.read<InvoiceProvider>().languageCode;
  }

  List<AppLanguage> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return AppLanguages.all;
    return AppLanguages.all.where((l) {
      return l.englishName.toLowerCase().contains(q) ||
          l.nativeName.toLowerCase().contains(q) ||
          l.code.toLowerCase().contains(q);
    }).toList();
  }

  void _select(AppLanguage language) {
    setState(() => _selected = language.code);
    context.read<InvoiceProvider>().setLanguage(language.code);
  }

  void _continue() {
    context.read<InvoiceProvider>().setLanguage(_selected);
    if (widget.fromOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BusinessNameScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = AppStrings.of(context);
    final languages = _filtered;

    return Scaffold(
      appBar: widget.fromOnboarding
          ? null
          : AppBar(title: Text(strings.selectLanguage)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.fromOnboarding) ...[
                const SizedBox(height: 12),
                Text(
                  strings.selectLanguage,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(strings.selectLanguageSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                const SizedBox(height: 20),
              ],
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: strings.searchLanguage,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final language = languages[i];
                    final selected = language.code == _selected;
                    return Material(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.10)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _select(language),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : (theme.extension<AppSemanticColors>()?.border ?? theme.dividerColor),
                              width: selected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(language.flag, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      language.nativeName,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    Text(language.englishName, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                                  ],
                                ),
                              ),
                              Icon(
                                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: selected ? theme.colorScheme.primary : muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _continue,
                child: Text(strings.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
