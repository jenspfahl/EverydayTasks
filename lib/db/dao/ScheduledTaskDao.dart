import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/ScheduledTaskEntity.dart';

@dao
abstract class ScheduledTaskDao {

  @Query('SELECT * FROM ScheduledTaskEntity '
      'ORDER BY createdAt DESC, id DESC')
  Future<List<ScheduledTaskEntity>> findAll();

  @Query('SELECT * FROM ScheduledTaskEntity WHERE taskTemplateId = :taskTemplateId '
      'ORDER BY createdAt DESC, id DESC')
  Future<List<ScheduledTaskEntity>> findByTaskTemplateId(int taskTemplateId);

  @Query('SELECT * FROM ScheduledTaskEntity WHERE taskTemplateVariantId = :taskTemplateVariantId '
      'ORDER BY createdAt DESC, id DESC')
  Future<List<ScheduledTaskEntity>> findByTaskTemplateVariantId(int taskTemplateVariantId);

  @Query('SELECT count(*) FROM ScheduledTaskEntity WHERE taskGroupId = :taskGroupId ')
  Stream<int?>  countByTaskGroupId(int taskGroupId);

  @Query('SELECT * FROM ScheduledTaskEntity WHERE id = :id')
  Stream<ScheduledTaskEntity?> findById(int id);

  @insert
  Future<int> insertScheduledTask(ScheduledTaskEntity scheduledTaskEntity);

  @update
  Future<int> updateScheduledTask(ScheduledTaskEntity scheduledTaskEntity);

  @delete
  Future<int> deleteScheduledTask(ScheduledTaskEntity scheduledTaskEntity);
}

