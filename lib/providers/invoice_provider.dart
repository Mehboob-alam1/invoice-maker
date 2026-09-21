import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class InvoiceProvider extends ChangeNotifier {
  static const _storageKey = 'invoice_app_state';

  String businessName = '';
  String businessEmail = '';
  String businessPhone = '';
  String businessAddress = '';
  String languageCode = 'en';
  bool isPro = false;

  final List<Client> clients = [];
  final List<Invoice> invoices = [];
  final List<InvoiceItem> catalogItems = [];

  bool get hasCompletedOnboarding => businessName.isNotEmpty;

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      businessName = json['businessName'] as String? ?? '';
      businessEmail = json['businessEmail'] as String? ?? '';
      businessPhone = json['businessPhone'] as String? ?? '';
      businessAddress = json['businessAddress'] as String? ?? '';
      languageCode = json['languageCode'] as String? ?? 'en';
      isPro = json['isPro'] as bool? ?? false;
      clients
        ..clear()
        ..addAll(
          (json['clients'] as List? ?? []).map(
            (e) => Client.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      invoices
        ..clear()
        ..addAll(
          (json['invoices'] as List? ?? []).map(
            (e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      catalogItems
        ..clear()
        ..addAll(
          (json['catalogItems'] as List? ?? []).map(
            (e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      notifyListeners();
    } catch (_) {
      // Ignore corrupt storage and start fresh.
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'businessName': businessName,
        'businessEmail': businessEmail,
        'businessPhone': businessPhone,
        'businessAddress': businessAddress,
        'languageCode': languageCode,
        'isPro': isPro,
        'clients': clients.map((e) => e.toJson()).toList(),
        'invoices': invoices.map((e) => e.toJson()).toList(),
        'catalogItems': catalogItems.map((e) => e.toJson()).toList(),
      }),
    );
  }

  void setBusinessProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) {
    if (name != null) businessName = name.trim();
    if (email != null) businessEmail = email.trim();
    if (phone != null) businessPhone = phone.trim();
    if (address != null) businessAddress = address.trim();
    notifyListeners();
    _save();
  }

  void setBusinessName(String name) => setBusinessProfile(name: name);

  void setLanguage(String code) {
    languageCode = code;
    notifyListeners();
    _save();
  }

  void unlockPro() {
    isPro = true;
    notifyListeners();
    _save();
  }

  Client addClient({required String name, String? email, String? phone, String? address}) {
    final client = Client(
      id: _newId(),
      name: name,
      email: email,
      phone: phone,
      address: address,
    );
    clients.add(client);
    notifyListeners();
    _save();
    return client;
  }

  Client findOrCreateClient({required String name, String? email, String? phone}) {
    for (final client in clients) {
      if (client.name.toLowerCase() == name.toLowerCase()) return client;
    }
    return addClient(name: name, email: email, phone: phone);
  }

  void updateClient(Client updated) {
    final index = clients.indexWhere((c) => c.id == updated.id);
    if (index >= 0) clients[index] = updated;
    for (var i = 0; i < invoices.length; i++) {
      if (invoices[i].client.id == updated.id) {
        invoices[i] = invoices[i].copyWith(client: updated);
      }
    }
    notifyListeners();
    _save();
  }

  void deleteClient(String id) {
    clients.removeWhere((c) => c.id == id);
    notifyListeners();
    _save();
  }

  InvoiceItem addCatalogItem({
    required String description,
    required double unitCost,
    int quantity = 1,
    String? notes,
  }) {
    final item = InvoiceItem(
      id: _newId(),
      description: description,
      notes: notes,
      unitCost: unitCost,
      quantity: quantity,
    );
    catalogItems.add(item);
    notifyListeners();
    _save();
    return item;
  }

  void updateCatalogItem(InvoiceItem updated) {
    final index = catalogItems.indexWhere((i) => i.id == updated.id);
    if (index >= 0) catalogItems[index] = updated;
    notifyListeners();
    _save();
  }

  void deleteCatalogItem(String id) {
    catalogItems.removeWhere((i) => i.id == id);
    notifyListeners();
    _save();
  }

  Invoice createInvoice({
    required Client client,
    required List<InvoiceItem> items,
    String currency = 'USD',
  }) {
    final invoice = Invoice(
      id: _newId(),
      number: '#INV.${(invoices.length + 1).toString().padLeft(3, '0')}',
      client: client,
      items: List.of(items),
      date: DateTime.now(),
      currency: currency,
    );
    invoices.insert(0, invoice);
    notifyListeners();
    _save();
    return invoice;
  }

  List<Invoice> get unpaidInvoices =>
      invoices.where((i) => i.status != InvoiceStatus.paid).toList();

  List<Invoice> get paidInvoices =>
      invoices.where((i) => i.status == InvoiceStatus.paid).toList();

  Invoice? invoiceById(String id) {
    try {
      return invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  void setInvoiceStatus(String id, InvoiceStatus status) {
    final index = invoices.indexWhere((i) => i.id == id);
    if (index < 0) return;
    invoices[index] = invoices[index].copyWith(status: status);
    notifyListeners();
    _save();
  }

  void markPaid(Invoice invoice) => setInvoiceStatus(invoice.id, InvoiceStatus.paid);

  void deleteInvoice(String id) {
    invoices.removeWhere((i) => i.id == id);
    notifyListeners();
    _save();
  }
}
