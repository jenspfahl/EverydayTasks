import 'dart:ui';

import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/When.dart';

import 'Severity.dart';
import 'TemplateId.dart';

class TaskEvent implements Comparable {
  int? id;
  int? taskGroupId;
  TemplateId? originTemplateId;

  String title;
  String? description;
  DateTime createdAt = DateTime.now();
  DateTime startedAt;
  AroundWhenAtDay aroundStartedAt;
  Duration duration;
  AroundDurationHours aroundDuration;
  Severity severity = Severity.MEDIUM;
  bool favorite = false;

  TaskEvent(
      this.id,
      this.taskGroupId,
      this.originTemplateId,
      this.title,
      this.description,
      this.createdAt,
      this.startedAt,
      this.aroundStartedAt,
      this.duration,
      this.aroundDuration,
      this.severity,
      this.favorite,
      );


  DateTime get finishedAt => startedAt.add(duration);


  @override
  int compareTo(other) {
    int result = other.aroundStartAt.compareTo(startedAt);
    if (result != 0) return result;
    return other.id??0.compareTo(id??0);
  }

}