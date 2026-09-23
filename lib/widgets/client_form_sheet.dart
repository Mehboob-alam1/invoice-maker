import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/client.dart';

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
    showDragHandle: true,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final strings = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.client == null ? strings.addClient : strings.editClient,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                strings.clientFormHelp,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
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
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.phoneNumber,
                  hintText: strings.phoneHint,
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
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
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxId,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.taxId,
                  hintText: strings.taxIdHint,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
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
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _save,
                child: Text(strings.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
