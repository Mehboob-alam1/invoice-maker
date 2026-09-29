import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../models/client.dart';
import 'blue_screen.dart';

class ClientFormResult {
  const ClientFormResult({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxId,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxId;
}

Future<ClientFormResult?> showClientFormSheet(
    BuildContext context, {
      Client? client,
    }) {
  return showModalBottomSheet<ClientFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The sheet paints its own rounded surface and drag handle (see build).
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) => ClientFormSheet(client: client),
  );
}

class ClientFormSheet extends StatefulWidget {
  final Client? client;

  const ClientFormSheet({super.key, this.client});

  @override
  State<ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends State<ClientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _taxId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.client?.name ?? '');
    _phone = TextEditingController(text: widget.client?.phone ?? '');
    _email = TextEditingController(text: widget.client?.email ?? '');
    _address = TextEditingController(text: widget.client?.address ?? '');
    _taxId = TextEditingController(text: widget.client?.taxId ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _taxId.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ClientFormResult(
        name: _name.text.trim(),
        phone: _emptyToNull(_phone.text),
        email: _emptyToNull(_email.text),
        address: _emptyToNull(_address.text),
        taxId: _emptyToNull(_taxId.text),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  InputDecorationTheme _inputTheme(ThemeData base) {
    final scheme = base.colorScheme;
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.primary.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: outline(scheme.primary.withValues(alpha: 0.12), 1),
      enabledBorder: outline(scheme.primary.withValues(alpha: 0.12), 1),
      focusedBorder: outline(scheme.primary, 2),
      errorBorder: outline(scheme.error, 1.5),
      focusedErrorBorder: outline(scheme.error, 2),
      floatingLabelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
      hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4)),
      errorStyle: const TextStyle(fontWeight: FontWeight.w600),
      prefixIconColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.focused)
            ? scheme.primary
            : scheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = buildBlueTheme(Theme.of(context));
    final themed = base.copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
      inputDecorationTheme: _inputTheme(base),
    );
    return Theme(data: themed, child: Builder(builder: _buildContent));
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : BlueColors.navy;
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3).toDouble();
    final tile = 52.0 * textScale;
    final strings = context.l10n;

    final nameField = TextFormField(
      controller: _name,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofocus: widget.client == null,
      decoration: InputDecoration(
        labelText: strings.name,
        hintText: strings.clientNameHint,
        prefixIcon: const Icon(Icons.person_rounded),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return strings.enterName;
        }
        return null;
      },
    );

    final phoneField = TextFormField(
      controller: _phone,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: strings.phoneNumber,
        hintText: strings.phoneHint,
        prefixIcon: const Icon(Icons.phone_rounded),
      ),
    );

    final emailField = TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: strings.email,
        hintText: strings.emailHint,
        prefixIcon: const Icon(Icons.email_rounded),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return null;
        if (!text.contains('@') || !text.contains('.')) {
          return strings.enterValidEmail;
        }
        return null;
      },
    );

    final taxField = TextFormField(
      controller: _taxId,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: strings.taxId,
        hintText: strings.taxIdHint,
        prefixIcon: const Icon(Icons.badge_outlined),
      ),
    );

    final addressField = TextFormField(
      controller: _address,
      keyboardType: TextInputType.streetAddress,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      minLines: 2,
      maxLines: 3,
      onFieldSubmitted: (_) => _save(),
      decoration: InputDecoration(
        labelText: strings.address,
        hintText: strings.addressHint,
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.location_on_rounded),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final hPad = w < 360 ? 16.0 : 22.0;
            final twoCols = w >= 520;
            const gap = 12.0;

            Widget pair(Widget a, Widget b) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: a),
                const SizedBox(width: gap),
                Expanded(child: b),
              ],
            );

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 20 + bottom),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: tile,
                          height: tile,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [BlueColors.bright, BlueColors.sky],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: BlueColors.light.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.client == null ? Icons.person_add_alt_1_rounded : Icons.edit_rounded,
                            size: tile * 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  widget.client == null ? strings.addClient : strings.editClient,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strings.clientFormHelp,
                                style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    // Fields
                    if (twoCols) ...[
                      pair(nameField, phoneField),
                      const SizedBox(height: gap),
                      pair(emailField, taxField),
                    ] else ...[
                      nameField,
                      const SizedBox(height: gap),
                      phoneField,
                      const SizedBox(height: gap),
                      emailField,
                      const SizedBox(height: gap),
                      taxField,
                    ],
                    const SizedBox(height: gap),
                    addressField,
                    const SizedBox(height: 24),
                    _GradientSaveButton(label: strings.save, onPressed: _save),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Blue gradient primary button: min height 56, radius 16, soft glow.
class _GradientSaveButton extends StatelessWidget {
  const _GradientSaveButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BlueColors.bright, BlueColors.light],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BlueColors.light.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}