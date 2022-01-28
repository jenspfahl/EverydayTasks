import 'package:floor/floor.dart';

@entity
class ScheduledTaskEventEntity {
  @primaryKey
  final int? id;
  final int taskEventId;
  final int scheduledTaskId;
  final int createdAt;

  ScheduledTaskEventEntity(
      this.id,
      this.taskEventId,
      this.scheduledTaskId,
      this.createdAt,
      );
}