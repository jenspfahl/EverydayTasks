import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/ScheduledTaskEntity.dart';

import '../entity/ScheduledTaskFixedScheduleEntity.dart';

@dao
abstract class ScheduledTaskFixedScheduleDao {

  @Query('SELECT * FROM ScheduledTaskFixedScheduleEntity WHERE scheduledTaskId = :scheduledTaskId')
  Future<List<ScheduledTaskFixedScheduleEntity>> findByScheduledTaskId(int scheduledTaskId);

  @insert
  Future<int> insertFixedSchedule(ScheduledTaskFixedScheduleEntity scheduledTaskFixedScheduleEntity);

  @Query('DELETE FROM ScheduledTaskFixedScheduleEntity WHERE scheduledTaskId = :scheduledTaskId')
  Future<int?> deleteFixedScheduleByScheduledTaskId(int scheduledTaskId);
}

