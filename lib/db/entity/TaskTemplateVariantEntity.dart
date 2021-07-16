import 'package:floor/floor.dart';

@entity
class TaskTemplateVariant {
  @primaryKey
  final int id;
  final int taskTemplateId;

  final String name;
  final String description;
  final int? when;
  final int? whenExactly;
  final int? duration;
  final int? durationExactlyMinutes;
  final int? severity;
  final bool favorite;

  TaskTemplateVariant(this.id, this.taskTemplateId,
      this.name, this.description, this.when, this.whenExactly,
      this.duration, this.durationExactlyMinutes, this.severity, this.favorite);
}