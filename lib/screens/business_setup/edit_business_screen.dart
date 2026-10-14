import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../ads/ad_flows.dart';
import '../../services/engagement_service.dart';
import '../../services/paywall_analytics.dart';
import '../../core/utils/currency_format.dart';
import '../../widgets/logo_crop_dialog.dart';
import '../../widgets/signature_pad_dialog.dart';

import '../../core/constants/app_texts.dart';
import '../../l10n/app_strings.dart';
import '../../ads/ad_action.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/ui/app_page_shell.dart';

const double _kContentMaxWidth = 640;
const double _kTwoColumnBreakpoint = 640;

class EditBusinessScreen extends StatefulWidget {
  const EditBusinessScreen({super.key});

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _taxId;
  late final TextEditingController _bankName;
  late final TextEditingController _accountHolder;
  late final TextEditingController _iban;
  late final TextEditingController _wallet;
  late final TextEditingController _paymentLink;
  late final TextEditingController _paymentNote;
  late final TextEditingController _taxLabel;
  late final TextEditingController _taxRate;
  late String _currency;
  late bool _taxInclusive;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();
    _name = TextEditingController(text: provider.businessName);
    _email = TextEditingController(text: provider.businessEmail);
    _phone = TextEditingController(text: provider.businessPhone);
    _address = TextEditingController(text: provider.businessAddress);
    _taxId = TextEditingController(text: provider.businessTaxId);
    _bankName = TextEditingController(text: provider.bankName);
    _accountHolder = TextEditingController(text: provider.accountHolder);
    _iban = TextEditingController(text: provider.iban);
    _wallet = TextEditingController(text: provider.wallet);
    _paymentLink = TextEditingController(text: provider.paymentLink);
    _paymentNote = TextEditingController(text: provider.paymentNote);
    _taxLabel = TextEditingController(text: provider.defaultTaxLabel);
    _taxRate = TextEditingController(
      text: provider.defaultTaxRate == 0 ? '' : provider.defaultTaxRate.toString(),
    );
    _currency = provider.defaultCurrency.isEmpty ? 'USD' : provider.defaultCurrency;
    _taxInclusive = provider.defaultTaxInclusive;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _taxId.dispose();
    _bankName.dispose();
    _accountHolder.dispose();
    _iban.dispose();
    _wallet.dispose();
    _paymentLink.dispose();
    _paymentNote.dispose();
    _taxLabel.dispose();
    _taxRate.dispose();
    super.dispose();
  }

  Future<void> _storeBytes(List<int> bytes, String name, {required bool logo, bool signature = false, bool stamp = false}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    context.read<InvoiceProvider>().setBusinessProfile(
      businessLogoPath: logo ? file.path : null,
      signaturePath: signature ? file.path : null,
      stampPath: stamp ? file.path : null,
    );
  }

  Future<void> _pickLogo({required bool stamp}) async {
    if (stamp && !context.read<InvoiceProvider>().isPro) {
      await openPaywallIfFree(context, source: PaywallSource.other);
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final cropped = await LogoCropDialog.show(context, bytes);
    if (cropped == null) return;
    await _storeBytes(
      cropped,
      stamp ? 'business_stamp.png' : 'business_logo.png',
      logo: !stamp,
      stamp: stamp,
    );
  }

  Future<void> _drawSignature() async {
    final bytes = await SignaturePadDialog.show(context);
    if (bytes == null) return;
    await _storeBytes(bytes, 'business_signature.png', logo: false, signature: true);
  }

  void _save() {
    context.read<InvoiceProvider>().setBusinessProfile(
      name: _name.text.trim().isEmpty
          ? AppTexts.defaultBusinessName
          : _name.text.trim(),
      email: _email.text,
      phone: _phone.text,
      address: _address.text,
      taxId: _taxId.text,
      bankName: _bankName.text,
      accountHolder: _accountHolder.text,
      iban: _iban.text,
      wallet: _wallet.text,
      paymentLink: _paymentLink.text,
      paymentNote: _paymentNote.text,
      defaultCurrency: _currency,
      defaultTaxLabel: _taxLabel.text,
      defaultTaxRate: double.tryParse(_taxRate.text.trim()) ?? 0,
      defaultTaxInclusive: _taxInclusive,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final hints = EngagementService.instance.paymentHints(
            context.read<InvoiceProvider>().languageCode,
          );

          final nameField = TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.businessNameHint,
              prefixIcon: const Icon(Icons.business_rounded),
            ),
          );
          final emailField = TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: strings.businessEmail,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
          );
          final phoneField = TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.businessPhone,
              prefixIcon: const Icon(Icons.call_rounded),
            ),
          );
          final taxField = TextField(
            controller: _taxId,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: strings.taxId,
              hintText: strings.taxIdHint,
              prefixIcon: const Icon(Icons.receipt_long_rounded),
            ),
          );
          final addressField = TextField(
            controller: _address,
            minLines: 2,
            maxLines: 3,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: strings.businessAddress,
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Icon(Icons.location_on_rounded),
              ),
            ),
          );

          return Scaffold(
            appBar: AppBar(title: Text(strings.manageBusiness)),
            body: AppPageShell(
              child: LayoutBuilder(
                builder: (context, c) {
                  final twoColumns = c.maxWidth >= _kTwoColumnBreakpoint;
                  final hPad = c.maxWidth < 360 ? 16.0 : 20.0;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints:
                      const BoxConstraints(maxWidth: _kContentMaxWidth),
                      child: ListView(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          8,
                          hPad,
                          24 + MediaQuery.viewPaddingOf(context).bottom,
                        ),
                        children: [
                          _LogoHeader(
                            nameController: _name,
                            note: strings.logo,
                            logoPath: context.watch<InvoiceProvider>().businessLogoPath,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _pickLogo(stamp: false),
                                icon: const Icon(Icons.image_outlined),
                                label: Text(strings.logo),
                              ),
                              OutlinedButton.icon(
                                onPressed: _drawSignature,
                                icon: const Icon(Icons.draw_outlined),
                                label: Text(strings.signature),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickLogo(stamp: true),
                                icon: const Icon(Icons.approval_outlined),
                                label: Text(strings.stamp),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(strings.stampPro, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _taxLabel,
                            decoration: InputDecoration(labelText: strings.taxName),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _taxRate,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: strings.taxRate),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(strings.taxInclusive),
                            value: _taxInclusive,
                            onChanged: (value) => setState(() => _taxInclusive = value),
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration: InputDecoration(labelText: strings.defaultCurrency),
                            items: CurrencyFormat.supportedCodes
                                .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _currency = value);
                            },
                          ),
                          const SizedBox(height: 24),
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
                                  color: BlueColors.bright
                                      .withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                nameField,
                                const SizedBox(height: 14),
                                if (twoColumns)
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: emailField),
                                      const SizedBox(width: 14),
                                      Expanded(child: phoneField),
                                    ],
                                  )
                                else ...[
                                  emailField,
                                  const SizedBox(height: 14),
                                  phoneField,
                                ],
                                const SizedBox(height: 14),
                                taxField,
                                const SizedBox(height: 14),
                                addressField,
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(strings.howToPay, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bankName,
                            decoration: InputDecoration(
                              labelText: strings.bankName,
                              hintText: hints.bank,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _accountHolder,
                            decoration: InputDecoration(labelText: strings.accountHolder),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _iban,
                            decoration: InputDecoration(labelText: strings.ibanOrAccount),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _wallet,
                            decoration: InputDecoration(
                              labelText: strings.mobileWallet,
                              hintText: hints.wallet,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _paymentLink,
                            decoration: InputDecoration(labelText: strings.paymentLink),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _paymentNote,
                            maxLines: 3,
                            decoration: InputDecoration(labelText: strings.paymentNote),
                          ),
                          const SizedBox(height: 24),
                          BlueGradientButton(
                            label: strings.save,
                            icon: Icons.check_rounded,
                            onPressed: () => runWithInterstitial(context, _save),
                          ),
                        ],
                      ),
                    ),
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

/// Logo placeholder that shows the business initial and updates as you type.
class _LogoHeader extends StatelessWidget {
  const _LogoHeader({required this.nameController, required this.note, required this.logoPath});

  final TextEditingController nameController;
  final String note;
  final String logoPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [BlueColors.bright, BlueColors.sky],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: BlueColors.bright.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: logoPath.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.file(
                    File(logoPath),
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.storefront_rounded, size: 42, color: Colors.white),
                  ),
                )
              : ValueListenableBuilder<TextEditingValue>(
            valueListenable: nameController,
            builder: (context, value, _) {
              final trimmed = value.text.trim();
              if (trimmed.isEmpty) {
                return const Icon(Icons.storefront_rounded,
                    size: 42, color: Colors.white);
              }
              final initial =
              String.fromCharCode(trimmed.runes.first).toUpperCase();
              return Text(
                initial,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  note,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}