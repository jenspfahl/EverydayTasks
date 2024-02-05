import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:ordinal_formatter/ordinal_formatter.dart';
import 'package:personaltasklogger/main.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/util/units.dart';

import 'i18n.dart';


final DAY_OF_MONTH_NUMBERS = HashMap<String, Map<int, String>>(); // language, then day of month --> ordinal day

Future<void> fillDayNumberCache() async {
  final it = SUPPORTED_LANGUAGES.iterator;
  while (it.moveNext()) {
    final language = it.current;
    final langMap = HashMap<int, String>();

    for (int i = 0; i <= 31; i++) {
      final ordinal = await _getOrdinalDayFor(i, language);
      debugPrint("DAYCACHE: $language $i --> $ordinal");
      langMap[i] = ordinal;
      DAY_OF_MONTH_NUMBERS[language] = langMap;
    }
  }

}

Future<String> _getOrdinalDayFor(int i, String language) async {
  String ordinalNumber;
  try {
    ordinalNumber = await OrdinalFormatter().format(i, language) ?? '$i';
  } on PlatformException catch (e) {
    ordinalNumber = '$i';
  }
  return ordinalNumber;
}

String getOrdinalDayOf(String language, int day) {
  final langMap = DAY_OF_MONTH_NUMBERS[language];
  if (langMap == null) {
    debugPrint("DAYCACHE: GET OF $language not found");
    return day.toString();
  }
  final lang = langMap[day];
  debugPrint("DAYCACHE: GET OF $day in $langMap");

  return lang ?? day.toString();
}


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
  final word = formatToWord(dateTime);
  if (word != null) {
    return makeWhenOnLowerCase ? word.toLowerCase() : word;
  }
  if (withPreposition) {
    return translate('common.words.on_for_dates') + " " + formatToDate(dateTime, context);
  }
  return formatToDate(dateTime, context);
}

String? formatToWord(DateTime dateTime) {
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

String formatToDate(DateTime dateTime, BuildContext context, {bool? showWeekdays, bool hideYear = false}) {
  final preferenceService = PreferenceService();
  final prefShowWeekdays = preferenceService.showWeekdays;
  final dateFormatSelection = preferenceService.dateFormatSelection;
  return formatToDateWithFormatSelection(dateTime, context, dateFormatSelection, showWeekdays ?? prefShowWeekdays, hideYear);
}

formatToDateWithFormatSelection(DateTime dateTime, BuildContext context, int dateFormatSelection, bool showWeekdays, bool hideYear) {
  final isSameYear = dateTime.year == DateTime.now().year;
  final formatter = getDateFormat(context, dateFormatSelection, showWeekdays, isSameYear || hideYear);
  return formatter.format(dateTime);
}


// day: 0..6
String formatAllYearDate(AllYearDate allYearDate, BuildContext context) {
  final date = DateTime(2024, allYearDate.month.index + 1, allYearDate.day); // leap year needed to display 29th Feb
  return formatToDate(date, context, showWeekdays: false, hideYear: true);
}

// day: 0..6
String getDayOfMonth(int day, BuildContext context) {
  final language = currentLocale(context).languageCode.toString();
  debugPrint("DAYCACHE GET: $language $day");
  return getOrdinalDayOf(language, day);
}

// day: 0..6
String getNarrowWeekdayOf(int day, BuildContext context) {
  final locale = currentLocale(context).toString();
  initializeDateFormatting(locale);
  return DateFormat.EEEE(locale).dateSymbols.NARROWWEEKDAYS[(day + 1) % 7];
}

// day: 0..6
String getShortWeekdayOf(int day, BuildContext context) {
  final locale = currentLocale(context).toString();
  initializeDateFormatting(locale);
  return DateFormat.EEEE(locale).dateSymbols.SHORTWEEKDAYS[(day + 1) % 7];
}

String getMonthOf(int month, BuildContext context) {
  final locale = currentLocale(context).toString();
  initializeDateFormatting(locale);
  return DateFormat.MMM(locale).dateSymbols.MONTHS[month];
}

getDateFormat(BuildContext context, int dateFormatSelection, bool showWeekdays, bool withoutYear) {

   final locale = currentLocale(context).toString();
  initializeDateFormatting(locale);
  if (showWeekdays) {
    final yMEd = withoutYear ? DateFormat.MEd(locale) : DateFormat.yMEd(locale);
    final yMMMEd = withoutYear ? DateFormat.MMMEd(locale) : DateFormat.yMMMEd(locale);
    final yMMMMEEEEd = withoutYear ? DateFormat.MMMMEEEEd(locale) : DateFormat.yMMMMEEEEd(locale);
    final isoWithE = DateFormat('E, yyyy-MM-dd');
    final withWeekdays = [yMEd, yMMMEd, yMMMMEEEEd, isoWithE];

    return withWeekdays.elementAt(dateFormatSelection);
  }
  else {
    final yMd = withoutYear ? DateFormat.Md(locale) : DateFormat.yMd(locale);
    final yMMMd = withoutYear ? DateFormat.MMMd(locale) : DateFormat.yMMMd(locale);
    final yMMMMd = withoutYear ? DateFormat.MMMMd(locale) : DateFormat.yMMMMd(locale);
    final iso = DateFormat('yyyy-MM-dd');
    final withoutWeekdays = [yMd, yMMMd, yMMMMd, iso];

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
    DateTime? trackingFinishedAt,
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
    final finishedAt = trackingFinishedAt ?? startedAt.add(duration);
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
  var seconds = Seconds(duration.inSeconds, clause);
  var durationText = minutes.toString();
  if (days.value.abs() >= 700) { // more than almost 2 years
    var aroundYears = (days.value / 365).round();
    var years = Years(aroundYears, clause);
    durationText = "${translate('common.words.around')} $years";
  }
  else if (days.value.abs() >= 365) { // more than 1 year
    var years = Years(days.value ~/ 365, clause);
    var aroundMonths = ((days.value - (365 * years.value)) / 30).round();
    var remainingAroundMonths = Months(aroundMonths, clause);
    if (remainingAroundMonths.value != 0) {
      durationText = "${translate('common.words.around')} $years ${translate('common.words.and')} $remainingAroundMonths";
    }
    else {
      durationText = "${translate('common.words.around')} $years";
    }
  }
  else if (days.value.abs() >= 80) {
    var aroundMonths = (days.value / 30).round();
    var months = Months(aroundMonths, clause);
    durationText = "${translate('common.words.around')} $months";
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
  else {
    var remainingSeconds = Seconds(seconds.value % 60, clause);
    if (minutes.value == 0) {
      durationText = seconds.toString();
    }
    else if (remainingSeconds.value != 0) {
      durationText = "$minutes ${translate('common.words.and')} $remainingSeconds";
    }
    else {
      durationText = minutes.toString();
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

WhenOnDatePast fromDateTimeToWhenOnDatePast(DateTime dateTime) {
  if (isToday(dateTime)) {
    return WhenOnDatePast.TODAY;
  } else if (isYesterday(dateTime)) {
    return WhenOnDatePast.YESTERDAY;
  } else if (isBeforeYesterday(dateTime)) {
    return WhenOnDatePast.BEFORE_YESTERDAY;
  } else {
    return WhenOnDatePast.CUSTOM;
  }
}
WhenOnDateFuture fromDateTimeToWhenOnDateFuture(DateTime dateTime) {
  if (isToday(dateTime)) {
    return WhenOnDateFuture.TODAY;
  } else if (isTomorrow(dateTime)) {
    return WhenOnDateFuture.TOMORROW;
  } else if (isAfterTomorrow(dateTime)) {
    return WhenOnDateFuture.AFTER_TOMORROW;
  } else {
    return WhenOnDateFuture.CUSTOM;
  }
}
