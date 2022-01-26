import 'package:floor/floor.dart';

@entity
class TaskEventEntity {
  @primaryKey
  final int? id;
  final int? taskGroupId;
  final int? originTaskTemplateId;
  final int? originTaskTemplateVariantId;

  final String title;
  final String? description;
  final int createdAt;
  final int startedAt;
  final int aroundStartedAt;
  final int duration;
  final int aroundDuration;
  final int severity;
  final bool favorite;

  TaskEventEntity(
      this.id,
      this.taskGroupId,
      this.originTaskTemplateId,
      this.originTaskTemplateVariantId,
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
}