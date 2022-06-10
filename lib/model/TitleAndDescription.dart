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


}