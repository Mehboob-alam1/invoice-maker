import 'package:flutter/material.dart';

import 'subscription_tier.dart';

enum InvoiceTemplateId {
  classic,
  modern,
  minimal,
  aurora,
  sunset,
  ocean,
  emerald,
  royal,
  rose,
  midnight,
  redModern,
  blueYellow,
  blueCorporate,
  orangeReceipt,
}

extension InvoiceTemplateIdStorage on InvoiceTemplateId {
  static InvoiceTemplateId fromStorage(String? raw) {
    return InvoiceTemplateId.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => InvoiceTemplateId.classic,
    );
  }
}

class InvoiceTemplateInfo {
  const InvoiceTemplateInfo({
    required this.id,
    required this.labelKey,
    required this.descriptionKey,
    this.proOnly = false,
    this.previewGradient,
  });

  final InvoiceTemplateId id;
  final String labelKey;
  final String descriptionKey;
  final bool proOnly;
  final List<Color>? previewGradient;

  String get storageId => id.name;

  static const freeTemplates = [
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.classic,
      labelKey: 'templateClassic',
      descriptionKey: 'templateClassicDesc',
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.modern,
      labelKey: 'templateModern',
      descriptionKey: 'templateModernDesc',
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.minimal,
      labelKey: 'templateMinimal',
      descriptionKey: 'templateMinimalDesc',
    ),
  ];

  static const premiumTemplates = [
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.aurora,
      labelKey: 'templateAurora',
      descriptionKey: 'templateAuroraDesc',
      proOnly: true,
      previewGradient: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF97316)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.sunset,
      labelKey: 'templateSunset',
      descriptionKey: 'templateSunsetDesc',
      proOnly: true,
      previewGradient: [Color(0xFFF97316), Color(0xFFEF4444), Color(0xFFBE123C)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.ocean,
      labelKey: 'templateOcean',
      descriptionKey: 'templateOceanDesc',
      proOnly: true,
      previewGradient: [Color(0xFF0EA5E9), Color(0xFF2563EB), Color(0xFF1E3A8A)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.emerald,
      labelKey: 'templateEmerald',
      descriptionKey: 'templateEmeraldDesc',
      proOnly: true,
      previewGradient: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF064E3B)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.royal,
      labelKey: 'templateRoyal',
      descriptionKey: 'templateRoyalDesc',
      proOnly: true,
      previewGradient: [Color(0xFF4F46E5), Color(0xFF312E81), Color(0xFFCA8A04)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.rose,
      labelKey: 'templateRose',
      descriptionKey: 'templateRoseDesc',
      proOnly: true,
      previewGradient: [Color(0xFFF472B6), Color(0xFFE11D48), Color(0xFF9D174D)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.midnight,
      labelKey: 'templateMidnight',
      descriptionKey: 'templateMidnightDesc',
      proOnly: true,
      previewGradient: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF6366F1)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.redModern,
      labelKey: 'templateRedModern',
      descriptionKey: 'templateRedModernDesc',
      proOnly: true,
      previewGradient: [Color(0xFF7B1E3A), Color(0xFF1B1B1B), Color(0xFFF6F2EC)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.blueYellow,
      labelKey: 'templateBlueYellow',
      descriptionKey: 'templateBlueYellowDesc',
      proOnly: true,
      previewGradient: [Color(0xFF14224E), Color(0xFFE4B84C), Color(0xFF1D2E66)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.blueCorporate,
      labelKey: 'templateBlueCorporate',
      descriptionKey: 'templateBlueCorporateDesc',
      proOnly: true,
      previewGradient: [Color(0xFF14304F), Color(0xFF9FD8D6), Color(0xFF16283F)],
    ),
    InvoiceTemplateInfo(
      id: InvoiceTemplateId.orangeReceipt,
      labelKey: 'templateOrangeReceipt',
      descriptionKey: 'templateOrangeReceiptDesc',
      proOnly: true,
      previewGradient: [Color(0xFF1F2937), Color(0xFFE0872A), Color(0xFFF3E9DD)],
    ),
  ];

  static List<InvoiceTemplateInfo> get all => [...freeTemplates, ...premiumTemplates];

  static InvoiceTemplateInfo infoFor(InvoiceTemplateId id) {
    return all.firstWhere((t) => t.id == id, orElse: () => freeTemplates.first);
  }

  static bool requiresPro(InvoiceTemplateId id) => premiumTemplates.any((t) => t.id == id);

  static bool canUseTemplate(InvoiceTemplateId id, SubscriptionTier tier) {
    if (!requiresPro(id)) return true;
    return tier.canUsePremiumTemplates;
  }

  static InvoiceTemplateId resolveForUser(InvoiceTemplateId id, SubscriptionTier tier) {
    if (canUseTemplate(id, tier)) return id;
    return InvoiceTemplateId.classic;
  }
}
