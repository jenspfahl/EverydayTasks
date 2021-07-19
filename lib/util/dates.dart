import 'package:intl/intl.dart';

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

String formatToDateTimeRange(DateTime start, DateTime end) {
  var duration = end.difference(start);
  String durationText = formatDuration(duration);
  return "${formatToTime(start)} - ${formatToTime(end)} ($durationText)";
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
