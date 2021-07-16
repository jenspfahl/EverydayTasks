import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';

@dao
abstract class TaskEventDao {
  @Query('SELECT * FROM TaskEvent')
  Future<List<TaskEventEntity>> findAll();

  @Query('SELECT * FROM TaskEvent WHERE id = :id')
  Stream<TaskEventEntity?> findById(int id);

  @insert
  Future<int> insertTaskEvent(TaskEventEntity taskEvent);

  @update
  Future<int> updateTaskEvent(TaskEventEntity taskEvent);

  @delete
  Future<int> deleteTaskEvent(TaskEventEntity taskEvent);
}

