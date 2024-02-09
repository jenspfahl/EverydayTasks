import 'package:flutter/material.dart';
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

  void apply(TaskEvent newTaskEvent) {
    assert  (id == newTaskEvent.id);
    taskGroupId = newTaskEvent.taskGroupId;
    title = newTaskEvent.title;
    description = newTaskEvent.description;
    createdAt = newTaskEvent.createdAt;
    severity = newTaskEvent.severity;
    startedAt = newTaskEvent.startedAt;
    aroundStartedAt = newTaskEvent.aroundStartedAt;
    duration = newTaskEvent.duration;
    aroundDuration = newTaskEvent.aroundDuration;
    trackingFinishedAt = newTaskEvent.trackingFinishedAt;
    favorite = newTaskEvent.favorite;
    originTemplateId = newTaskEvent.originTemplateId;
  }

  bool isAroundStartAtTheSameAsActualTime() => TimeOfDay.fromDateTime(startedAt) == When.fromWhenAtDayToTimeOfDay(aroundStartedAt, TimeOfDay.fromDateTime(startedAt));

}