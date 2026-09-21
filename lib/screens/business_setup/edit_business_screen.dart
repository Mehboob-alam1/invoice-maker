import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_texts.dart';
import '../../l10n/app_strings.dart';
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

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();
    _name = TextEditingController(text: provider.businessName);
    _email = TextEditingController(text: provider.businessEmail);
    _phone = TextEditingController(text: provider.businessPhone);
    _address = TextEditingController(text: provider.businessAddress);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    context.read<InvoiceProvider>().setBusinessProfile(
          name: _name.text.trim().isEmpty ? AppTexts.defaultBusinessName : _name.text.trim(),
          email: _email.text,
          phone: _phone.text,
          address: _address.text,
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
          TextField(controller: _name, decoration: InputDecoration(labelText: strings.businessNameHint)),
          const SizedBox(height: 12),
          TextField(controller: _email, decoration: InputDecoration(labelText: strings.businessEmail)),
          const SizedBox(height: 12),
          TextField(controller: _phone, decoration: InputDecoration(labelText: strings.businessPhone)),
          const SizedBox(height: 12),
          TextField(controller: _address, maxLines: 2, decoration: InputDecoration(labelText: strings.businessAddress)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: Text(strings.save)),
        ],
      ),
    );
  }
}
