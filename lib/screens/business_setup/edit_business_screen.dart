import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();
    _name = TextEditingController(text: provider.businessName);
    _email = TextEditingController(text: provider.businessEmail);
    _phone = TextEditingController(text: provider.businessPhone);
    _address = TextEditingController(text: provider.businessAddress);
    _taxId = TextEditingController(text: provider.businessTaxId);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _taxId.dispose();
    super.dispose();
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
                            note: strings.companyLogoComingSoon,
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
  const _LogoHeader({required this.nameController, required this.note});

  final TextEditingController nameController;
  final String note;

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
          child: ValueListenableBuilder<TextEditingValue>(
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