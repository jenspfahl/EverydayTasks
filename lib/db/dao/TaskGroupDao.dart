import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';

import '../entity/TaskGroupEntity.dart';

@dao
abstract class TaskGroupDao {

  @Query('SELECT * FROM TaskGroupEntity ORDER BY id DESC')
  Future<List<TaskGroupEntity>> findAll();

  @Query('SELECT * FROM TaskGroupEntity WHERE id = :id')
  Stream<TaskGroupEntity?> findById(int id);

  @insert
  Future<int> insertTaskGroup(TaskGroupEntity taskGroup);

  @update
  Future<int> updateTaskGroup(TaskGroupEntity taskGroup);

  @delete
  Future<int> deleteTaskGroup(TaskGroupEntity taskGroup);
}

