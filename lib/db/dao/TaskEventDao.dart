import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';

@dao
abstract class TaskEventDao {
  @Query('SELECT * FROM TaskEvent')
  Stream<TaskEventEntity> findAll();

  @Query('SELECT * FROM TaskEvent WHERE id = :id')
  Stream<TaskEventEntity?> findById(int id);

  @insert
  Future<void> insertTaskEvent(TaskEventEntity taskEvent);

  @update
  Future<void> updateTaskEvent(TaskEventEntity taskEvent);

  @delete
  Future<void> deleteTaskEvent(TaskEventEntity taskEvent);
}

