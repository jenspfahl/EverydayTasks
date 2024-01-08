import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/util/extensions.dart';

final String I18N_PREFIX = "\$i18n{";
final String I18N_POSTFIX = "}";

Locale currentLocale(BuildContext context) {
  final localizationDelegate = LocalizedApp.of(context).delegate;
  return localizationDelegate.currentLocale;
}

Locale systemLocale(BuildContext context) {
  final localizationDelegate = LocalizedApp.of(context).delegate;

  final systemLanguage = Platform.localeName
      .split("_")
      .first;
  final appLanguages = localizationDelegate.supportedLocales
      .map((e) => e.languageCode);
  debugPrint("system language: $systemLanguage");
  final systemLanguageSupported = appLanguages.contains(systemLanguage);
  if (systemLanguageSupported) {
    return Locale(systemLanguage);
  }
  else {
    return localizationDelegate.currentLocale;
  }

}

bool isI18nKey(String string) =>
    string.startsWith(I18N_PREFIX) && string.endsWith(I18N_POSTFIX);

String translateCapitalize(String key) {
  return translate(key).capitalize();
}

String translateI18nKey(String string) {
  if (isI18nKey(string)) {
    final key = extractI18nKey(string);
    //debugPrint("extracted i18n key: $key");
    return translate(key);
  }
  else {
    return string;
  }
}

String extractI18nKey(String string) =>
    string.substring(I18N_PREFIX.length, string.length - I18N_POSTFIX.length);

bool isEqualToTranslation(String text, String key) {
  final translated = translateI18nKey(key);
  return translated == text.trim();
}

String wrapToI18nKey(String key) {
  return I18N_PREFIX + key + I18N_POSTFIX;
}

String tryWrapToI18nKey(String text, String key) {
  if (isEqualToTranslation(text, key)) {
    return key;
  }
  else {
    return text;
  }
}