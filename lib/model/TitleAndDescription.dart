import 'package:personaltasklogger/model/When.dart';

import '../util/i18n.dart';
import 'Severity.dart';
import 'TemplateId.dart';

abstract class TitleAndDescription {
  String title;
  String? description;

  TitleAndDescription(
    this.title,
    this.description,
    );

  String get translatedTitle => translateI18nKey(title);

  String? get translatedDescription => description != null ? translateI18nKey(description!) : null;

  static String? createPredefinedI18nKey(String string, String? i18nKey, String oldSubKey, String inBetweenSubKey, String newSubKey) {
    if (i18nKey != null && isI18nKey(string)) {
      final key = extractI18nKey(string);
      final newKey = key.substring(0,key.indexOf(".$oldSubKey")) + ".$inBetweenSubKey." + i18nKey + "." + newSubKey;
      return wrapToI18nKey(newKey);

    }
    else {
      return i18nKey;
    }
  }

}