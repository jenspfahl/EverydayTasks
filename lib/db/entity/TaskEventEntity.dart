import 'package:floor/floor.dart';

@entity
class TaskEventEntity {
  @primaryKey
  final int? id;
  final int? taskGroupId;

  final String name;
  final String? description;
  final int? colorRGB;
  final int startedAt;
  final int finishedAt;
  final int severity;
  final bool favorite;

  TaskEventEntity(this.id, this.taskGroupId, this.name, this.description, this.colorRGB,
      this.startedAt, this.finishedAt, this.severity, this.favorite);
}