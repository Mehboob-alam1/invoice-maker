import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice_item.dart';
import '../../providers/invoice_provider.dart';
import '../../ads/ad_action.dart';
import '../../services/invoice_create_gate.dart';
import '../../navigation/invoice_flow.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/ui/app_page_shell.dart';

const double _kContentMaxWidth = 640;

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
    final strings = AppStrings.read(context);
    final combinedInput = '${_clientController.text}\n${_descriptionController.text}';
    if (!await ensureAiGenerationAllowed(context, inputText: combinedInput)) return;
    if (!mounted) return;
    if (!await ensureInvoiceQuotaOrPrompt(context)) return;
    setState(() => _generating = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final provider = context.read<InvoiceProvider>();
    final estimatedTokens = InvoiceProvider.estimateAiTokensForInput(combinedInput);
    provider.recordAiTokenUsage(estimatedTokens);
    final clientName =
    _clientController.text.trim().isEmpty ? strings.newClientFallback : _clientController.text.trim();
    final client = provider.findOrCreateClient(name: clientName);
    final invoice = provider.createInvoice(
      client: client,
      items: _itemsFromDescription(_descriptionController.text, strings.serviceThisMonth),
    );

    if (!mounted) return;
    setState(() => _generating = false);
    await showInterstitialWithLoadingIfEligible(context);
    if (!mounted) return;
    await navigateAfterInvoiceCreated(context, invoice.id);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final provider = context.watch<InvoiceProvider>();
    final maxChars = provider.maxAiInputCharacters;

    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return Scaffold(
            appBar: AppBar(title: Text(strings.createWithAi)),
            body: AppPageShell(
              child: LayoutBuilder(
                builder: (context, c) {
                  final hPad = c.maxWidth < 360 ? 14.0 : 20.0;

                  return Column(
                    children: [
                      // Scrollable form (keeps working with the keyboard open).
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
                            child: SingleChildScrollView(
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _AiHeroCard(
                                    intro: strings.aiIntro,
                                    tokens: strings.aiTokensRemainingHint(
                                      provider.aiTokensRemainingThisMonth,
                                      provider.monthlyAiTokenLimit,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: scheme.primary.withValues(alpha: 0.12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: BlueColors.bright.withValues(alpha: 0.08),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _FieldLabel(strings.clientNameOptional),
                                        TextField(
                                          controller: _clientController,
                                          textCapitalization: TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            hintText: strings.clientNameHintAi,
                                            prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        _FieldLabel(strings.writeInvoiceDetail),
                                        TextField(
                                          controller: _descriptionController,
                                          minLines: 4,
                                          maxLines: 8,
                                          maxLength: maxChars,
                                          keyboardType: TextInputType.multiline,
                                          textCapitalization: TextCapitalization.sentences,
                                          decoration: InputDecoration(
                                            hintText: strings.invoiceThisMonthHint,
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Action area pinned to the bottom.
                      SafeArea(
                        top: false,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _GenerateButton(
                                  loading: _generating,
                                  label: _generating ? strings.generating : strings.generateInvoice,
                                  onPressed: _generating ? null : _generate,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  strings.aiFillHint,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Intro card: gradient background, sparkle icon and the remaining-tokens chip.
class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard({required this.intro, required this.tokens});
  final String intro;
  final String tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BlueColors.deep, BlueColors.bright, Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: BlueColors.bright.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    intro,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tokens,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient button with a loading state (dims and shows a spinner).
class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: loading ? 0.75 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [BlueColors.bright, BlueColors.light]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: BlueColors.bright.withValues(alpha: loading ? 0.12 : 0.30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                      : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(label, style: style, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}