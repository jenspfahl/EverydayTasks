import 'package:flutter/foundation.dart';
import 'package:flutter_translate/flutter_translate.dart';

final String I18N_PREFIX = "\$i18n{";
final String I18N_POSTFIX = "}";

bool isI18nKey(String string) =>
    string.startsWith(I18N_PREFIX) && string.endsWith(I18N_POSTFIX);


String translateI18nKey(String string) {
  if (isI18nKey(string)) {
    final key = extractI18nKey(string);
    debugPrint("extracted i18n key: $key");
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