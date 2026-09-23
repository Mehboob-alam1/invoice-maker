import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_texts.dart';
import '../../l10n/app_strings.dart';
import '../../ads/ad_action.dart';
import '../../providers/invoice_provider.dart';

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
          name: _name.text.trim().isEmpty ? AppTexts.defaultBusinessName : _name.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: Text(strings.manageBusiness)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            strings.companyLogoComingSoon,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: InputDecoration(labelText: strings.businessNameHint)),
          const SizedBox(height: 12),
          TextField(controller: _email, decoration: InputDecoration(labelText: strings.businessEmail)),
          const SizedBox(height: 12),
          TextField(controller: _phone, decoration: InputDecoration(labelText: strings.businessPhone)),
          const SizedBox(height: 12),
          TextField(controller: _taxId, decoration: InputDecoration(labelText: strings.taxId, hintText: strings.taxIdHint)),
          const SizedBox(height: 12),
          TextField(controller: _address, maxLines: 2, decoration: InputDecoration(labelText: strings.businessAddress)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => runWithInterstitial(context, _save),
            child: Text(strings.save),
          ),
        ],
      ),
    );
  }
}
