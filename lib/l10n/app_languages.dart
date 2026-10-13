import 'package:flutter/material.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
    required this.countryCode,
  });

  final String code;
  final String englishName;
  final String nativeName;
  final String flag;

  /// ISO 3166-1 alpha-2 code used to draw the country flag.
  final String countryCode;

  bool get isRtl => code == 'ar' || code == 'ur' || code == 'fa';
}

class AppLanguages {
  AppLanguages._();

  static const List<AppLanguage> all = [
    AppLanguage(code: 'en', englishName: 'English', nativeName: 'English', flag: '🇺🇸', countryCode: 'us'),
    AppLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español', flag: '🇪🇸', countryCode: 'es'),
    AppLanguage(code: 'fr', englishName: 'French', nativeName: 'Français', flag: '🇫🇷', countryCode: 'fr'),
    AppLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch', flag: '🇩🇪', countryCode: 'de'),
    AppLanguage(code: 'it', englishName: 'Italian', nativeName: 'Italiano', flag: '🇮🇹', countryCode: 'it'),
    AppLanguage(code: 'pt', englishName: 'Portuguese', nativeName: 'Português', flag: '🇧🇷', countryCode: 'br'),
    AppLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية', flag: '🇸🇦', countryCode: 'sa'),
    AppLanguage(code: 'ur', englishName: 'Urdu', nativeName: 'اردو', flag: '🇵🇰', countryCode: 'pk'),
    AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳', countryCode: 'in'),
    AppLanguage(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷', countryCode: 'tr'),
    AppLanguage(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩', countryCode: 'id'),
    AppLanguage(code: 'zh', englishName: 'Chinese', nativeName: '中文', flag: '🇨🇳', countryCode: 'cn'),
    AppLanguage(code: 'ru', englishName: 'Russian', nativeName: 'Русский', flag: '🇷🇺', countryCode: 'ru'),
    AppLanguage(code: 'ja', englishName: 'Japanese', nativeName: '日本語', flag: '🇯🇵', countryCode: 'jp'),
    AppLanguage(code: 'ko', englishName: 'Korean', nativeName: '한국어', flag: '🇰🇷', countryCode: 'kr'),
    AppLanguage(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱', countryCode: 'nl'),
    AppLanguage(code: 'pl', englishName: 'Polish', nativeName: 'Polski', flag: '🇵🇱', countryCode: 'pl'),
    AppLanguage(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩', countryCode: 'bd'),
    AppLanguage(code: 'fa', englishName: 'Persian', nativeName: 'فارسی', flag: '🇮🇷', countryCode: 'ir'),
    AppLanguage(code: 'ms', englishName: 'Malay', nativeName: 'Bahasa Melayu', flag: '🇲🇾', countryCode: 'my'),
  ];

  static List<Locale> get supportedLocales =>
      all.map((l) => Locale(l.code)).toList();

  static AppLanguage byCode(String code) {
    return all.firstWhere((l) => l.code == code, orElse: () => all.first);
  }
}
