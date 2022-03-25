import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personaltasklogger/model/When.dart';

DateTime fillToWholeDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 9999);
}

DateTime truncToDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

DateTime truncToSeconds(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute);
}

String formatToDateOrWord(DateTime dateTime, [bool? withPreposition]) {
  if (isToday(dateTime)) {
    return "Today";
  }
  if (isYesterday(dateTime)) {
    return "Yesterday";
  }
  if (isBeforeYesterday(dateTime)) {
    return "Before yesterday";
  }
  if (isTomorrow(dateTime)) {
    return "Tomorrow";
  }
  if (isAfterTomorrow(dateTime)) {
    return "After tomorrow";
  }
  if (withPreposition ?? false) {
    return "on " + formatToDate(dateTime);
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

String formatTrackingDuration(Duration duration) {
  var hours = duration.inHours  % (24 * 24 * 60);
  var minutes = duration.inMinutes % (24 * 60);
  var seconds = duration.inSeconds % 60;

  if (hours > 0 && minutes > 0) {
    return "$hours hours $minutes minutes $seconds seconds";
  }
  else if (minutes > 0) {
    return "$minutes minutes $seconds seconds";
  }
  else {
    return "$seconds seconds";
  }
}

String formatToDateTimeRange(
    AroundWhenAtDay aroundStartedAt,
    DateTime startedAt,
    AroundDurationHours aroundDurationHours,
    Duration duration,
    bool showAround) {


  final sb = StringBuffer();
  if (showAround && aroundStartedAt != AroundWhenAtDay.NOW && aroundStartedAt != AroundWhenAtDay.CUSTOM) {
    sb.write(When.fromWhenAtDayToString(aroundStartedAt));
  }
  else {
    sb.write(formatToTime(startedAt));
    sb.write(" - ");
    if (showAround && aroundDurationHours != AroundDurationHours.CUSTOM) {
      sb.write("~");
    }
    final finishedAt = startedAt.add(duration);
    sb.write(formatToTime(finishedAt));
  }

  sb.write(" (");
  if (showAround && aroundDurationHours != AroundDurationHours.CUSTOM) {
    sb.write(When.fromDurationHoursToString(aroundDurationHours));
  }
  else {
    sb.write(formatDuration(duration));
  }
  sb.write(")");

  return sb.toString();
}

String formatDuration(Duration duration, [bool? avoidNegativeDurationString]) {
  if (avoidNegativeDurationString ?? false) {
    duration = duration.abs();
  }
  var days = duration.inDays;
  var hours = duration.inHours;
  var minutes = duration.inMinutes;
  var durationText = "$minutes minutes";
  if (days.abs() >= 62) {
    var months = days ~/ 31;
    durationText = "$months months";

  }
  else if (days.abs() >= 7) {
    var remainingDays = days % 7;
    var weeks = days ~/ 7;
    if (remainingDays != 0) {
      durationText = "$weeks weeks and $remainingDays days";
    }
    else {
      durationText = "$weeks weeks";
    }
  }
  else if (hours.abs() >= 24) {
    var remainingHours = hours % 24;
    if (remainingHours != 0) {
      durationText = "$days days and $remainingHours hours";
    }
    else {
      durationText = "$days days";
    }
  }
  else if (minutes.abs() >= 60) {
    var remainingMinutes = minutes % 60;
    if (remainingMinutes != 0) {
      durationText = "$hours hours and $remainingMinutes minutes";
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


bool isAfterTomorrow(DateTime? dateTime) {
  if (dateTime == null) return false;
  return truncToDate(dateTime) == truncToDate(DateTime.now().add(Duration(days: 2)));
}

bool isTomorrow(DateTime? dateTime) {
  if (dateTime == null) return false;
  return truncToDate(dateTime) == truncToDate(DateTime.now().add(Duration(days: 1)));
}

bool isToday(DateTime? dateTime) {
  if (dateTime == null) return false;
  return truncToDate(dateTime) == truncToDate(DateTime.now());
}

bool isYesterday(DateTime? dateTime) {
  if (dateTime == null) return false;
  return truncToDate(dateTime) == truncToDate(DateTime.now().subtract(Duration(days: 1)));
}

bool isBeforeYesterday(DateTime? dateTime) {
  if (dateTime == null) return false;
  return truncToDate(dateTime) == truncToDate(DateTime.now().subtract(Duration(days: 2)));
}

WhenOnDate fromDateTimeToWhenOnDate(DateTime dateTime) {
  if (isToday(dateTime)) {
    return WhenOnDate.TODAY;
  } else if (isYesterday(dateTime)) {
    return WhenOnDate.YESTERDAY;
  } else if (isBeforeYesterday(dateTime)) {
    return WhenOnDate.BEFORE_YESTERDAY;
  } else {
    return WhenOnDate.CUSTOM;
  }
}