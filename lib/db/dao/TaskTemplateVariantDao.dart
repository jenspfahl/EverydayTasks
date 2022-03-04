import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateVariantEntity.dart';

@dao
abstract class TaskTemplateVariantDao {

  @Query('SELECT * FROM TaskTemplateVariantEntity ORDER BY id DESC')
  Future<List<TaskTemplateVariantEntity>> findAll();

  @Query('SELECT MAX(id) as MAX_ID FROM TaskTemplateVariantEntity')
  Future<int?> findMaxId();

  @Query('SELECT * FROM TaskTemplateVariantEntity ORDER BY id DESC')
  Future<List<TaskTemplateVariantEntity>> findAllFavs();

  @Query('SELECT * FROM TaskTemplateVariantEntity WHERE id = :id')
  Stream<TaskTemplateVariantEntity?> findById(int id);

  @insert
  Future<int> insertTaskTemplateVariant(TaskTemplateVariantEntity taskTemplateVariant);

  @update
  Future<int> updateTaskTemplateVariant(TaskTemplateVariantEntity taskTemplateVariant);

  @delete
  Future<int> deleteTaskTemplateVariant(TaskTemplateVariantEntity taskTemplateVariant);
}

