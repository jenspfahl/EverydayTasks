import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';

@dao
abstract class TaskTemplateDao {

  @Query('SELECT * FROM TaskTemplateEntity ORDER BY id DESC')
  Future<List<TaskTemplateEntity>> findAll();

  @Query('SELECT * FROM TaskTemplateEntity ORDER BY id DESC')
  Future<List<TaskTemplateEntity>> findAllFavs();

  @Query('SELECT * FROM TaskTemplateEntity WHERE id = :id')
  Stream<TaskTemplateEntity?> findById(int id);

  @insert
  Future<int> insertTaskTemplate(TaskTemplateEntity taskTemplate);

  @update
  Future<int> updateTaskTemplate(TaskTemplateEntity taskTemplate);

  @delete
  Future<int> deleteTaskTemplate(TaskTemplateEntity taskTemplate);
}

