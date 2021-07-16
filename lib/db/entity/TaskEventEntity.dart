import 'package:floor/floor.dart';

@entity
class TaskEventEntity {
  @primaryKey
  final int? id;

  final String name;
  final String? description;
  final String? originTaskGroup;
  final int? colorRGB;
  final int startedAt;
  final int finishedAt;
  final int severity;
  final bool favorite;

  TaskEventEntity(this.id, this.name, this.description, this.originTaskGroup, this.colorRGB,
      this.startedAt, this.finishedAt, this.severity, this.favorite);
}