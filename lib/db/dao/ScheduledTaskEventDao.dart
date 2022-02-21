import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/ScheduledTaskEventEntity.dart';
import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';

@dao
abstract class ScheduledTaskEventDao {

  @Query('SELECT * FROM ScheduledTaskEventEntity '
      'WHERE scheduledTaskId = :scheduledTaskId AND id < :lastId ORDER BY createdAt DESC, id DESC LIMIT :limit')
  Future<List<ScheduledTaskEventEntity>> findByScheduledTaskId(int scheduledTaskId, int lastId, int limit);

  @Query('SELECT * FROM ScheduledTaskEventEntity '
      'WHERE taskEventId = :taskEventId AND id < :lastId ORDER BY createdAt DESC, id DESC LIMIT :limit')
  Future<List<ScheduledTaskEventEntity>> findByTaskEventId(int taskEventId, int lastId, int limit);

  @Query('SELECT * FROM ScheduledTaskEventEntity WHERE id = :id')
  Stream<ScheduledTaskEventEntity?> findById(int id);

  @insert
  Future<int> insertScheduledTaskEvent(ScheduledTaskEventEntity scheduledTaskEventEntity);

  @update
  Future<int> updateScheduledTaskEvent(ScheduledTaskEventEntity scheduledTaskEventEntity);

  @delete
  Future<int> deleteScheduledTaskEvent(ScheduledTaskEventEntity scheduledTaskEventEntity);
}

