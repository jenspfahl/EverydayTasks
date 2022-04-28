import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
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

String formatToDateOrWord(DateTime dateTime, BuildContext context,
    {bool withPreposition = false, bool withWeekDay = false, bool makeWhenOnLowerCase = false}) {
  final word = _formatToWord(dateTime);
  if (word != null) {
    return makeWhenOnLowerCase ? word.toLowerCase() : word;
  }
  if (withPreposition) {
    return "on " + formatToDate(dateTime, context, withWeekDay);
  }
  return formatToDate(dateTime, context, withWeekDay);
}
String? _formatToWord(DateTime dateTime) {
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
  return null;
}

String formatToDate(DateTime dateTime, BuildContext context, [bool withWeekDay = false]) {
  final locale = Localizations.localeOf(context).languageCode;
  initializeDateFormatting(locale);
  final DateFormat formatter = withWeekDay ? DateFormat.yMMMEd(locale) : DateFormat.yMMMd(locale) ;
  return formatter.format(dateTime);
}

String formatToDateTime(DateTime dateTime, BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  initializeDateFormatting(locale);

  final DateFormat dateFormatter = DateFormat.yMd(locale);
  final DateFormat timeFormatter = DateFormat.Hms(locale);
  return dateFormatter.format(dateTime) + " " + timeFormatter.format(dateTime);
}

String formatToTime(DateTime dateTime) {
  final DateFormat formatter = DateFormat('H:mm');
  return formatter.format(dateTime);
}

String formatTrackingDuration(Duration duration) {
  var hours = duration.inHours;
  var minutes = duration.inMinutes % 60;
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
  var days = Days(duration.inDays);
  var hours = Hours(duration.inHours);
  var minutes = Minutes(duration.inMinutes);
  var durationText = minutes.toString();
  if (days.value.abs() >= 62) {
    var months = Months(days.value ~/ 31);
    durationText = months.toString();

  }
  else if (days.value.abs() >= 7) {
    var remainingDays = Days(days.value % 7);
    var weeks = Weeks(days.value ~/ 7);
    if (remainingDays.value != 0) {
      durationText = "$weeks and $remainingDays";
    }
    else {
      durationText = weeks.toString();
    }
  }
  else if (hours.value.abs() >= 24) {
    var remainingHours = Hours(hours.value % 24);
    if (remainingHours.value != 0) {
      durationText = "$days and $remainingHours";
    }
    else {
      durationText = days.toString();
    }
  }
  else if (minutes.value.abs() >= 60) {
    var remainingMinutes = Minutes(minutes.value % 60);
    if (remainingMinutes.value != 0) {
      durationText = "$hours and $remainingMinutes";
    }
    else {
      durationText = hours.toString();
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


abstract class Unit {
    num value;

    Unit(this.value);
    String getSingleUnitAsString();
    String getPluralUnitAsString();

    @override
    String toString() {
      final unit = value == 1 ? getSingleUnitAsString() : getPluralUnitAsString();
      return "$value $unit";
    }

}

class Months extends Unit {

  Months(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "month";
  }

  @override
  String getPluralUnitAsString() {
    return "months";
  }
}

class Weeks extends Unit {

  Weeks(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "week";
  }

  @override
  String getPluralUnitAsString() {
    return "weeks";
  }
}

class Days extends Unit {

  Days(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "day";
  }

  @override
  String getPluralUnitAsString() {
    return "days";
  }
}

class Hours extends Unit {

  Hours(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "hour";
  }

  @override
  String getPluralUnitAsString() {
    return "hours";
  }
}

class Minutes extends Unit {

  Minutes(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "minute";
  }

  @override
  String getPluralUnitAsString() {
    return "minutes";
  }
}

class Items extends Unit {

  Items(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "item";
  }

  @override
  String getPluralUnitAsString() {
    return "items";
  }
}