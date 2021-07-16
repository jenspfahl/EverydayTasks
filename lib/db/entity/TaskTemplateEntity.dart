import 'package:floor/floor.dart';

@entity
class TaskTemplate {
  @primaryKey
  final int id;
  final int? taskGroupId;

  final String name;
  final String description;
  final int? when;
  final int? whenExactly;
  final int? duration;
  final int? durationExactlyMinutes;
  final bool favorite;

  TaskTemplate(this.id, this.taskGroupId,
      this.name, this.description, this.when, this.whenExactly,
      this.duration, this.durationExactlyMinutes, this.favorite);
}