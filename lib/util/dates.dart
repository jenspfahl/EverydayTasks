import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personaltasklogger/model/When.dart';

DateTime truncToDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

String formatToDateOrWord(DateTime dateTime) {
  var today = truncToDate(DateTime.now());
  if (truncToDate(dateTime) == today) {
    return "Today";
  }
  var yesterday = truncToDate(DateTime.now().subtract(Duration(days: 1)));
  if (truncToDate(dateTime) == yesterday) {
    return "Yesterday";
  }
  return formatToDate(dateTime);
}

String formatToDate(DateTime dateTime) {
  final DateFormat formatter = DateFormat('yyyy-MMM-dd');
  return formatter.format(dateTime);
}

String formatToDateTime(DateTime dateTime) {
  final DateFormat formatter = DateFormat('yyyy-MMM-dd H:mm');
  return formatter.format(dateTime);
}

String formatToTime(DateTime dateTime) {
  final DateFormat formatter = DateFormat('H:mm');
  return formatter.format(dateTime);
}

String formatToDateTimeRange(
    AroundWhenAtDay aroundStartedAt,
    DateTime startedAt,
    AroundDurationHours aroundDurationHours,
    Duration duration,
    bool showAround) {

  final finishedAt = startedAt.add(duration);
  var rangeText = "${formatToTime(startedAt)} - ${formatToTime(finishedAt)}";
  if (showAround && aroundStartedAt != AroundWhenAtDay.NOW && aroundStartedAt != AroundWhenAtDay.CUSTOM) {
    rangeText = When.fromWhenAtDayToString(aroundStartedAt);
  }

  var durationText = formatDuration(duration);
  if (showAround && aroundDurationHours != AroundDurationHours.CUSTOM) {
    durationText = When.fromDurationHoursToString(aroundDurationHours);
  }
  return "$rangeText ($durationText)";
}

String formatDuration(Duration duration) {
  var minutes = duration.inMinutes;
  var durationText = "$minutes minutes";
  if (minutes >= 60) {
    var hours = duration.inHours;
    var remainingMinutes = minutes % 60;
    if (remainingMinutes != 0) {
      durationText = "$hours hours $remainingMinutes minutes";
    }
    else {
      durationText = "$hours hours";
    }
  }
  return durationText;
}

String formatTimeOfDay(TimeOfDay timeOfDay) {
  final formatter = new NumberFormat("00");
  return "${timeOfDay.hour}:${formatter.format(timeOfDay.minute)}";
}
