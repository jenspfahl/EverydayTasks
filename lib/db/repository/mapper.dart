
import 'package:flutter/material.dart';

import '../../model/TemplateId.dart';
import '../../model/TitleAndDescription.dart';
import '../../util/i18n.dart';
import 'TemplateRepository.dart';

int dateTimeToEntity(DateTime dateTime) => dateTime.millisecondsSinceEpoch;
DateTime dateTimeFromEntity(int fromEntity) => DateTime.fromMillisecondsSinceEpoch(fromEntity);

int timeOfDayToEntity(TimeOfDay timeOfDay) => timeOfDay.hour * 100 + timeOfDay.minute;
TimeOfDay timeOfDayFromEntity(int fromEntity) => new TimeOfDay(hour: fromEntity ~/ 100, minute: fromEntity % 100);


// In the past duration was saved as integer minutes. To distinguish saved in seconds we negate it
// and restore the Duration object accordingly
int durationToEntity(Duration duration) => -duration.inSeconds;
Duration durationFromEntity(int fromEntity) => fromEntity < 0
    ? Duration(seconds: -fromEntity)
    : Duration(minutes: fromEntity);


void tryWrapI18nForTitleAndDescription(
    TitleAndDescription modelToChange, TemplateId predefinedTemplateId) {
  final predefinedTemplate =
      TemplateRepository.findPredefinedTemplate(predefinedTemplateId);

  final wrappedTitle =
      tryWrapToI18nKey(modelToChange.title, predefinedTemplate.title);
  modelToChange.title = wrappedTitle;

  if (modelToChange.description != null &&
      predefinedTemplate.description != null) {
    final wrappedDescription = tryWrapToI18nKey(
        modelToChange.description!, predefinedTemplate.description!);
    modelToChange.description = wrappedDescription;
  }
}