import 'package:floor/floor.dart';

@entity
class ScheduledTaskEntity {
  @primaryKey
  final int? id;
  final int taskGroupId;
  final int? taskTemplateId;
  final int? taskTemplateVariantId;

  final String title;
  final String? description;
  final int createdAt;

  final int? aroundStartAt;
  final int? startAt;

  final int? repetitionAfter;
  final int? exactRepetitionAfterDays;

  final int? lastScheduledEventAt;
  final bool active;

  ScheduledTaskEntity(
      this.id,
      this.taskGroupId,
      this.taskTemplateId,
      this.taskTemplateVariantId,
      this.title,
      this.description,
      this.createdAt,
      this.aroundStartAt,
      this.startAt,
      this.repetitionAfter,
      this.exactRepetitionAfterDays,
      this.lastScheduledEventAt,
      this.active,
      );
}