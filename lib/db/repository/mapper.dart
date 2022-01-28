
import 'package:flutter/material.dart';

int dateTimeToEntity(DateTime dateTime) => dateTime.millisecondsSinceEpoch;
DateTime dateTimeFromEntity(int fromEntity) => DateTime.fromMillisecondsSinceEpoch(fromEntity);

timeOfDayToEntity(TimeOfDay timeOfDay) => timeOfDay.hour * 100 + timeOfDay.minute;
TimeOfDay timeOfDayFromEntity(int fromEntity) => new TimeOfDay(hour: (fromEntity / 100).toInt(), minute: fromEntity % 100);


int durationToEntity(Duration duration) => duration.inMinutes;
Duration durationFromEntity(int fromEntity) => Duration(minutes: fromEntity);