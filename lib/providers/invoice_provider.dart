import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/subscription_tier.dart';

class InvoiceProvider extends ChangeNotifier {
  static const _storageKey = 'invoice_app_state';

  String businessName = '';
  String businessEmail = '';
  String businessPhone = '';
  String businessAddress = '';
  String businessTaxId = '';
  String languageCode = 'en';
  SubscriptionTier subscriptionTier = SubscriptionTier.free;
  bool onboardingLanguageDone = false;

  String _invoiceQuotaDayKey = '';
  int _invoicesCreatedOnQuotaDay = 0;

  String _aiQuotaMonthKey = '';
  int _aiTokensUsedThisMonth = 0;

  /// Legacy flag; true when tier is Pro (kept for older builds / Firestore).
  bool get isPro => subscriptionTier == SubscriptionTier.pro;

  bool get isPremiumOrAbove => subscriptionTier != SubscriptionTier.free;
  bool onboardingCarouselDone = false;
  bool onboardingGoogleStepDone = false;

  final List<Client> clients = [];
  final List<Invoice> invoices = [];
  final List<InvoiceItem> catalogItems = [];

  bool get hasCompletedOnboarding => businessName.isNotEmpty;

  /// Called after local profile changes to mirror data in Firestore (set from [main.dart]).
  Future<void> Function()? onCloudSyncRequested;

  bool _importingFromCloud = false;

  String get invoiceQuotaDayKeyForSync {
    _normalizeQuotaDay();
    return _invoiceQuotaDayKey;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void importFromCloudAccount({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String taxId,
    String? languageCode,
  }) {
    _importingFromCloud = true;
    if (name.isNotEmpty) businessName = name;
    if (email.isNotEmpty) businessEmail = email;
    if (phone.isNotEmpty) businessPhone = phone;
    if (address.isNotEmpty) businessAddress = address;
    if (taxId.isNotEmpty) businessTaxId = taxId;
    if (languageCode != null && languageCode.isNotEmpty) this.languageCode = languageCode;
    _importingFromCloud = false;
    notifyListeners();
    _save();
  }

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
      businessTaxId = json['businessTaxId'] as String? ?? '';
      languageCode = json['languageCode'] as String? ?? 'en';
      final tierRaw = json['subscriptionTier'] as String?;
      if (tierRaw != null) {
        subscriptionTier = SubscriptionTier.fromStorage(tierRaw);
      } else if (json['isPro'] as bool? ?? false) {
        subscriptionTier = SubscriptionTier.pro;
      }
      _invoiceQuotaDayKey = json['invoiceQuotaDayKey'] as String? ?? '';
      _invoicesCreatedOnQuotaDay = json['invoicesCreatedOnQuotaDay'] as int? ?? 0;
      _aiQuotaMonthKey = json['aiQuotaMonthKey'] as String? ?? '';
      _aiTokensUsedThisMonth = json['aiTokensUsedThisMonth'] as int? ?? 0;
      _normalizeQuotaDay();
      _normalizeAiQuotaMonth();
      onboardingLanguageDone = json['onboardingLanguageDone'] as bool? ?? false;
      onboardingCarouselDone = json['onboardingCarouselDone'] as bool? ?? false;
      onboardingGoogleStepDone = json['onboardingGoogleStepDone'] as bool? ?? false;
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
        'businessTaxId': businessTaxId,
        'languageCode': languageCode,
        'subscriptionTier': subscriptionTier.storageKey,
        'isPro': isPro,
        'invoiceQuotaDayKey': _invoiceQuotaDayKey,
        'invoicesCreatedOnQuotaDay': _invoicesCreatedOnQuotaDay,
        'aiQuotaMonthKey': _aiQuotaMonthKey,
        'aiTokensUsedThisMonth': _aiTokensUsedThisMonth,
        'onboardingLanguageDone': onboardingLanguageDone,
        'onboardingCarouselDone': onboardingCarouselDone,
        'onboardingGoogleStepDone': onboardingGoogleStepDone,
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
    String? taxId,
  }) {
    if (name != null) businessName = name.trim();
    if (email != null) businessEmail = email.trim();
    if (phone != null) businessPhone = phone.trim();
    if (address != null) businessAddress = address.trim();
    if (taxId != null) businessTaxId = taxId.trim();
    notifyListeners();
    _save();
    _requestCloudSync();
  }

  void setBusinessName(String name) => setBusinessProfile(name: name);

  void setLanguage(String code) {
    languageCode = code;
    notifyListeners();
    _save();
    _requestCloudSync();
  }

  void _requestCloudSync() {
    if (_importingFromCloud) return;
    final sync = onCloudSyncRequested;
    if (sync != null) sync();
  }

  void completeOnboardingLanguageStep() {
    onboardingLanguageDone = true;
    notifyListeners();
    _save();
  }

  void completeOnboardingCarouselStep() {
    onboardingCarouselDone = true;
    notifyListeners();
    _save();
  }

  void completeOnboardingGoogleStep() {
    onboardingGoogleStepDone = true;
    notifyListeners();
    _save();
  }

  /// Updated from verified store purchases ([SubscriptionService]) or Firestore restore.
  void setSubscriptionTier(SubscriptionTier tier) {
    if (subscriptionTier == tier) return;
    subscriptionTier = tier;
    notifyListeners();
    _save();
    _requestCloudSync();
  }

  /// @deprecated Use [setSubscriptionTier]. Kept for migration paths.
  void setPro(bool value) {
    setSubscriptionTier(value ? SubscriptionTier.pro : SubscriptionTier.free);
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _normalizeQuotaDay() {
    final today = _todayKey();
    if (_invoiceQuotaDayKey != today) {
      _invoiceQuotaDayKey = today;
      _invoicesCreatedOnQuotaDay = 0;
    }
  }

  int get dailyInvoiceLimit => subscriptionTier.dailyInvoiceLimit;

  int get invoicesCreatedToday {
    _normalizeQuotaDay();
    return _invoicesCreatedOnQuotaDay;
  }

  /// `null` when unlimited (Pro).
  int? get invoicesRemainingToday {
    final limit = dailyInvoiceLimit;
    if (limit < 0) return null;
    _normalizeQuotaDay();
    return (limit - _invoicesCreatedOnQuotaDay).clamp(0, limit);
  }

  bool get canCreateInvoiceToday {
    final limit = dailyInvoiceLimit;
    if (limit < 0) return true;
    _normalizeQuotaDay();
    return _invoicesCreatedOnQuotaDay < limit;
  }

  void _recordInvoiceCreatedForQuota() {
    _normalizeQuotaDay();
    _invoicesCreatedOnQuotaDay++;
    _save();
    _requestCloudSync();
  }

  static String _monthKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  void _normalizeAiQuotaMonth() {
    final month = _monthKey();
    if (_aiQuotaMonthKey != month) {
      _aiQuotaMonthKey = month;
      _aiTokensUsedThisMonth = 0;
    }
  }

  int get monthlyAiTokenLimit => subscriptionTier.monthlyAiTokenLimit;

  int get maxAiTokensPerRequest => subscriptionTier.maxAiTokensPerRequest;

  int get maxAiInputCharacters => subscriptionTier.maxAiInputCharacters;

  int get aiTokensUsedThisMonth {
    _normalizeAiQuotaMonth();
    return _aiTokensUsedThisMonth;
  }

  int get aiTokensRemainingThisMonth {
    final limit = monthlyAiTokenLimit;
    if (limit <= 0) return 0;
    _normalizeAiQuotaMonth();
    return (limit - _aiTokensUsedThisMonth).clamp(0, limit);
  }

  /// Fixed overhead + input text (~4 characters per token).
  static int estimateAiTokensForInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 280;
    final inputTokens = (trimmed.length / 4).ceil();
    return inputTokens + 250;
  }

  bool canAffordAiGeneration(int estimatedTokens) {
    if (!subscriptionTier.canUseAiInvoice) return false;
    if (estimatedTokens > maxAiTokensPerRequest) return false;
    _normalizeAiQuotaMonth();
    return _aiTokensUsedThisMonth + estimatedTokens <= monthlyAiTokenLimit;
  }

  void recordAiTokenUsage(int tokens) {
    if (tokens <= 0) return;
    _normalizeAiQuotaMonth();
    _aiTokensUsedThisMonth += tokens;
    _save();
    _requestCloudSync();
  }

  Client addClient({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
  }) {
    final client = Client(
      id: _newId(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      taxId: taxId,
    );
    clients.add(client);
    notifyListeners();
    _save();
    return client;
  }

  Client findOrCreateClient({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
  }) {
    for (final client in clients) {
      if (client.name.toLowerCase() == name.toLowerCase()) {
        final merged = client.copyWith(
          email: email ?? client.email,
          phone: phone ?? client.phone,
          address: address ?? client.address,
          taxId: taxId ?? client.taxId,
        );
        updateClient(merged);
        return merged;
      }
    }
    return addClient(name: name, email: email, phone: phone, address: address, taxId: taxId);
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

  Future<Invoice> createInvoice({
    required Client client,
    required List<InvoiceItem> items,
    String currency = 'USD',
    String? number,
    DateTime? date,
    DateTime? dueDate,
    double taxRate = 0,
    String? paymentTerms,
    String? poNumber,
    String? notes,
    String templateId = 'classic',
  }) async {
    final invoice = Invoice(
      id: _newId(),
      number: number?.trim().isNotEmpty == true
          ? number!.trim()
          : '#INV.${(invoices.length + 1).toString().padLeft(3, '0')}',
      client: Client(
        id: client.id,
        name: client.name,
        email: client.email,
        phone: client.phone,
        address: client.address,
        taxId: client.taxId,
      ),
      items: items
          .map(
            (e) => InvoiceItem(
              id: e.id,
              description: e.description,
              notes: e.notes,
              unitCost: e.unitCost,
              quantity: e.quantity,
            ),
          )
          .toList(),
      date: date ?? DateTime.now(),
      dueDate: dueDate,
      currency: currency,
      taxRate: taxRate,
      paymentTerms: paymentTerms,
      poNumber: poNumber,
      notes: notes,
      templateId: templateId,
    );
    invoices.insert(0, invoice);
    _recordInvoiceCreatedForQuota();
    notifyListeners();
    await _save();
    return invoice;
  }

  void updateInvoice(Invoice updated) {
    final index = invoices.indexWhere((i) => i.id == updated.id);
    if (index < 0) return;
    invoices[index] = updated;
    notifyListeners();
    _save();
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
