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

  final int aroundStartAt;
  final int? startAt;

  final int repetitionAfter;
  final int? exactRepetitionAfter;
  final int? exactRepetitionAfterUnit;

  final int? lastScheduledEventAt;
  final int? oneTimeDueOn;
  final int? oneTimeCompletedOn;

  final bool active;
  final bool? important;
  final int? pausedAt;

  final int? repetitionMode;

  bool? reminderNotificationEnabled;
  int? reminderNotificationPeriod;
  int? reminderNotificationUnit;

  bool? preNotificationEnabled;
  int? preNotificationPeriod;
  int? preNotificationUnit;


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
      this.exactRepetitionAfter,
      this.exactRepetitionAfterUnit,
      this.lastScheduledEventAt,
      this.oneTimeDueOn,
      this.oneTimeCompletedOn,
      this.active,
      this.important,
      this.pausedAt,
      this.repetitionMode,
      this.reminderNotificationEnabled,
      this.reminderNotificationPeriod,
      this.reminderNotificationUnit,
      this.preNotificationEnabled,
      this.preNotificationPeriod,
      this.preNotificationUnit,
      );
}