import 'package:personaltasklogger/model/When.dart';

import 'Severity.dart';

class TaskEvent implements Comparable {
  int? id;
  int? taskGroupId;

  String title;
  String? description;
  int? colorRGB;
  DateTime createdAt = DateTime.now();
  DateTime startedAt;
  AroundWhenAtDay aroundStartedAt;
  Duration duration;
  AroundDurationHours aroundDuration;
  Severity severity = Severity.MEDIUM;
  bool favorite = false;

  TaskEvent(this.id, this.taskGroupId, this.title, this.description, this.colorRGB, this.createdAt, 
      this.startedAt, this.aroundStartedAt, this.duration, this.aroundDuration, 
      this.severity, this.favorite);

    TaskEvent.newInstance(this.taskGroupId, this.title, this.description, this.colorRGB,
      this.startedAt, this.aroundStartedAt, this.duration, this.aroundDuration, this.severity);

    TaskEvent.newPlainInstance(this.title,
        this.startedAt, this.aroundStartedAt, this.duration, this.aroundDuration);

  DateTime get finishedAt => startedAt.add(duration);

  @override
  int compareTo(other) {
    int result = other.startedAt.compareTo(startedAt);
    if (result != 0) return result;
    return other.id??0.compareTo(id??0);
  }

}