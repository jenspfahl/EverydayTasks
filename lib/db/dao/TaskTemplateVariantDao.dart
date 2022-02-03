import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateVariantEntity.dart';

@dao
abstract class TaskTemplateVariantDao {

  @Query('SELECT * FROM TaskTemplateVariantEntity '
      'WHERE id < :lastId ORDER BY id DESC LIMIT :limit')
  Future<List<TaskTemplateVariantEntity>> findAllPaged(int lastId, int limit);

  @Query('SELECT * FROM TaskTemplateVariantEntity WHERE id = :id')
  Stream<TaskTemplateVariantEntity?> findById(int id);

  @insert
  Future<int> insertTaskTemplateVariant(TaskTemplateVariantEntity taskTemplateVariant);

  @update
  Future<int> updateTaskTemplateVariant(TaskTemplateVariantEntity taskTemplateVariant);

  @delete
  Future<int> deleteTaskTemplateVariant(TaskTemplateVariantEntity taskTemplateVariant);
}

