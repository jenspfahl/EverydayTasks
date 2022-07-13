import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/util/units.dart';

import 'i18n.dart';

DateTime fillToWholeDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 9999);
}

DateTime truncToDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

DateTime truncToMinutes(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute);
}

String formatToDateOrWord(DateTime dateTime, BuildContext context,
    {bool withPreposition = false, bool makeWhenOnLowerCase = false}) {
  final word = _formatToWord(dateTime);
  if (word != null) {
    return makeWhenOnLowerCase ? word.toLowerCase() : word;
  }
  if (withPreposition) {
    return translate('common.words.on_for_dates') + " " + formatToDate(dateTime, context);
  }
  return formatToDate(dateTime, context);
}

String? _formatToWord(DateTime dateTime) {
  if (isToday(dateTime)) {
    return translate('common.dates.today');
  }
  if (isYesterday(dateTime)) {
    return translate('common.dates.yesterday');
  }
  if (isBeforeYesterday(dateTime)) {
    return translate('common.dates.before_yesterday');
  }
  if (isTomorrow(dateTime)) {
    return translate('common.dates.tomorrow');
  }
  if (isAfterTomorrow(dateTime)) {
    return translate('common.dates.after_tomorrow');
  }
  return null;
}

String formatToDate(DateTime dateTime, BuildContext context) {
  final preferenceService = PreferenceService();
  final showWeekdays = preferenceService.showWeekdays;
  final dateFormatSelection = preferenceService.dateFormatSelection;
  return formatToDateWithFormatSelection(dateTime, context, dateFormatSelection, showWeekdays);
}

formatToDateWithFormatSelection(DateTime dateTime, BuildContext context, int dateFormatSelection, bool showWeekdays) {
  final isSameYear = dateTime.year == DateTime.now().year;
  final formatter = getDateFormat(context, dateFormatSelection, showWeekdays, isSameYear);
  return formatter.format(dateTime);
}

 getDateFormat(BuildContext context, int dateFormatSelection, bool showWeekdays, bool withoutYear) {

   final locale = currentLocale(context).toString();
  initializeDateFormatting(locale);
debugPrint('showWeekdays=$showWeekdays');
  if (showWeekdays) {
    final yMEd = withoutYear ? DateFormat.MEd(locale) : DateFormat.yMEd(locale);
    final yMMMEd = withoutYear ? DateFormat.MMMEd(locale) : DateFormat.yMMMEd(locale);
    final yMMMMEEEEd = withoutYear ? DateFormat.MMMMEEEEd(locale) : DateFormat.yMMMMEEEEd(locale);
    final withWeekdays = [yMEd, yMMMEd, yMMMMEEEEd];

    return withWeekdays.elementAt(dateFormatSelection);
  }
  else {
    final yMd = withoutYear ? DateFormat.Md(locale) : DateFormat.yMd(locale);
    final yMMMd = withoutYear ? DateFormat.MMMd(locale) : DateFormat.yMMMd(locale);
    final yMMMMd = withoutYear ? DateFormat.MMMMd(locale) : DateFormat.yMMMMd(locale);
    final withoutWeekdays = [yMd, yMMMd, yMMMMd];

    return withoutWeekdays.elementAt(dateFormatSelection);
  }

}

String formatToDateTime(DateTime dateTime, BuildContext context) {
  final locale = currentLocale(context).toString();
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
  var hours = Hours(duration.inHours);
  var minutes = Minutes(duration.inMinutes % 60);
  var seconds = Seconds(duration.inSeconds % 60);

  if (hours.value > 0) {
    return "$hours $minutes $seconds";
  }
  else if (minutes.value > 0) {
    return "$minutes $seconds";
  }
  else {
    return "$seconds";
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

  return sb.toString();
}

String formatToDuration(
    AroundDurationHours aroundDurationHours,
    Duration duration,
    bool showAround) {

  final sb = StringBuffer();

  if (showAround && aroundDurationHours != AroundDurationHours.CUSTOM) {
    sb.write(When.fromDurationHoursToString(aroundDurationHours));
  }
  else {
    sb.write(formatDuration(duration));
  }

  return sb.toString();
}

String formatDuration(Duration duration, [bool? avoidNegativeDurationString, Clause? clause]) {
  if (avoidNegativeDurationString ?? false) {
    duration = duration.abs();
  }
  var days = Days(duration.inDays, clause);
  var hours = Hours(duration.inHours, clause);
  var minutes = Minutes(duration.inMinutes, clause);
  var durationText = minutes.toString();
  if (days.value.abs() >= 730) { // more than 2 years
    var years = Years(days.value ~/ 365, clause);
    durationText = years.toString();

  }
  else if (days.value.abs() >= 62) {
    var months = Months(days.value ~/ 31, clause);
    durationText = months.toString();

  }
  else if (days.value.abs() >= 7) {
    var remainingDays = Days(days.value % 7, clause);
    var weeks = Weeks(days.value ~/ 7, clause);
    if (remainingDays.value != 0) {
      durationText = "$weeks ${translate('common.words.and')} $remainingDays";
    }
    else {
      durationText = weeks.toString();
    }
  }
  else if (hours.value.abs() >= 24) {
    var remainingHours = Hours(hours.value % 24, clause);
    if (remainingHours.value != 0) {
      durationText = "$days ${translate('common.words.and')} $remainingHours";
    }
    else {
      durationText = days.toString();
    }
  }
  else if (minutes.value.abs() >= 60) {
    var remainingMinutes = Minutes(minutes.value % 60, clause);
    if (remainingMinutes.value != 0) {
      durationText = "$hours ${translate('common.words.and')} $remainingMinutes";
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
