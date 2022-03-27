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