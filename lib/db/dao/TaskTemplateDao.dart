import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';

@dao
abstract class TaskTemplateDao {

  @Query('SELECT * FROM TaskTemplateEntity '
      'WHERE id < :lastId ORDER BY id DESC LIMIT :limit')
  Future<List<TaskTemplateEntity>> findAllPaged(int lastId, int limit);

  @Query('SELECT * FROM TaskTemplateEntity '
      'WHERE favorite = 1 AND id < :lastId ORDER BY id DESC LIMIT :limit')
  Future<List<TaskTemplateEntity>> findAllFavsPaged(int lastId, int limit);

  @Query('SELECT * FROM TaskTemplateEntity WHERE id = :id')
  Stream<TaskTemplateEntity?> findById(int id);

  @insert
  Future<int> insertTaskTemplate(TaskTemplateEntity taskTemplate);

  @update
  Future<int> updateTaskTemplate(TaskTemplateEntity taskTemplate);

  @delete
  Future<int> deleteTaskTemplate(TaskTemplateEntity taskTemplate);
}

