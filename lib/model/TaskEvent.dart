import 'package:personaltasklogger/model/When.dart';

import 'Severity.dart';
import 'TemplateId.dart';
import 'TitleAndDescription.dart';

class TaskEvent extends TitleAndDescription implements Comparable {
  int? id;
  int? taskGroupId;
  TemplateId? originTemplateId;

  DateTime createdAt = DateTime.now();
  DateTime startedAt;
  AroundWhenAtDay aroundStartedAt;
  Duration duration;
  AroundDurationHours aroundDuration;
  DateTime? trackingFinishedAt;
  Severity severity = Severity.MEDIUM;
  bool favorite = false;

  TaskEvent(
      this.id,
      this.taskGroupId,
      this.originTemplateId,
      String title,
      String? description,
      this.createdAt,
      this.startedAt,
      this.aroundStartedAt,
      this.duration,
      this.aroundDuration,
      this.trackingFinishedAt,
      this.severity,
      this.favorite,
      )
  : super(title, description);


  DateTime get finishedAt => trackingFinishedAt ?? startedAt.add(duration);

  DateTime get finishedAtForCalendar {
    final finished = finishedAt;
    if (finished.second >= 60 * 10) {
      return finished;
    }
    return startedAt.add(Duration(minutes: 10));
  }


  @override
  int compareTo(other) {
    int result = other.startedAt.compareTo(startedAt);
    if (result != 0) return result;
    return other.createdAt.compareTo(createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}