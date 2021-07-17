import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';

@dao
abstract class TaskEventDao {
  // TODO add paging
  @Query('SELECT * FROM TaskEventEntity ORDER BY startedAt DESC, id DESC')
  Future<List<TaskEventEntity>> findAll();

  @Query('SELECT * FROM TaskEventEntity WHERE id = :id')
  Stream<TaskEventEntity?> findById(int id);

  @insert
  Future<int> insertTaskEvent(TaskEventEntity taskEvent);

  @update
  Future<int> updateTaskEvent(TaskEventEntity taskEvent);

  @delete
  Future<int> deleteTaskEvent(TaskEventEntity taskEvent);
}

