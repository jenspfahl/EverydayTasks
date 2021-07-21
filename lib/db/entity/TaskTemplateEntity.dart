import 'package:floor/floor.dart';

@entity
class TaskTemplate {
  @primaryKey
  final int id;
  final int? taskGroupId;

  final String title;
  final String description;
  final int? startedAt;
  final int? aroundStartedAt;
  final int? duration;
  final int? aroundDuration;
  final int? severity;
  final bool favorite;

  TaskTemplate(this.id, this.taskGroupId,
      this.title, this.description, this.startedAt, this.aroundStartedAt,
      this.duration, this.aroundDuration, this.severity, this.favorite);
}