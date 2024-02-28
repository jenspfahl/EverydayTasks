import 'package:floor/floor.dart';

@Entity(indices: [
  Index(
    name: 'idx_ScheduledTaskFixedScheduleEntity_scheduledTaskId',
    value: ['scheduledTaskId'],
    unique: false,
  ),
])
class ScheduledTaskFixedScheduleEntity {

  @primaryKey
  final int? id;
  final int scheduledTaskId;
  final int type;
  final int value;


  ScheduledTaskFixedScheduleEntity(
      this.id,
      this.scheduledTaskId,
      this.type,
      this.value,
      );
}