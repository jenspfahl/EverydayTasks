import 'package:floor/floor.dart';

@Entity(indices: [
  Index(
    name: 'idx_ScheduledTaskEventEntity_taskEventId',
    value: ['taskEventId'],
    unique: false,
  ),
  Index(
    name: 'idx_ScheduledTaskEventEntity_scheduledTaskId',
    value: ['scheduledTaskId'],
    unique: false,
  ),
])
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