import 'package:flutter/material.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
  });

  final String code;
  final String englishName;
  final String nativeName;
  final String flag;

  bool get isRtl => code == 'ar' || code == 'ur' || code == 'fa';
}

class AppLanguages {
  AppLanguages._();

  static const List<AppLanguage> all = [
    AppLanguage(code: 'en', englishName: 'English', nativeName: 'English', flag: '🇺🇸'),
    AppLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    AppLanguage(code: 'fr', englishName: 'French', nativeName: 'Français', flag: '🇫🇷'),
    AppLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    AppLanguage(code: 'it', englishName: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    AppLanguage(code: 'pt', englishName: 'Portuguese', nativeName: 'Português', flag: '🇧🇷'),
    AppLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    AppLanguage(code: 'ur', englishName: 'Urdu', nativeName: 'اردو', flag: '🇵🇰'),
    AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    AppLanguage(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    AppLanguage(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
    AppLanguage(code: 'zh', englishName: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    AppLanguage(code: 'ru', englishName: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    AppLanguage(code: 'ja', englishName: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    AppLanguage(code: 'ko', englishName: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    AppLanguage(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
    AppLanguage(code: 'pl', englishName: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
    AppLanguage(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩'),
    AppLanguage(code: 'fa', englishName: 'Persian', nativeName: 'فارسی', flag: '🇮🇷'),
    AppLanguage(code: 'ms', englishName: 'Malay', nativeName: 'Bahasa Melayu', flag: '🇲🇾'),
  ];

  static List<Locale> get supportedLocales =>
      all.map((l) => Locale(l.code)).toList();

  static AppLanguage byCode(String code) {
    return all.firstWhere((l) => l.code == code, orElse: () => all.first);
  }
}
