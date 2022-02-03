import 'package:floor/floor.dart';

@entity
class TaskTemplateEntity {
  @primaryKey
  final int? id;
  final int taskGroupId;

  final String title;
  final String? description;
  final int? startedAt;
  final int? aroundStartedAt;
  final int? duration;
  final int? aroundDuration;
  final int? severity;
  final bool favorite;

  TaskTemplateEntity(this.id, this.taskGroupId,
      this.title, this.description, this.startedAt, this.aroundStartedAt,
      this.duration, this.aroundDuration, this.severity, this.favorite);
}