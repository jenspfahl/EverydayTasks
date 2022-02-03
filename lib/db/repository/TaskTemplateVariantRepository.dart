
import 'package:personaltasklogger/db/entity/TaskTemplateVariantEntity.dart';
import 'package:personaltasklogger/db/repository/IdPaging.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/model/When.dart';

import '../database.dart';
import 'mapper.dart';

class TaskTemplateVariantRepository {

  static Future<TaskTemplateVariant> insert(TaskTemplateVariant taskTemplateVariant) async {

    final database = await getDb();

    final taskTemplateVariantDao = database.taskTemplateVariantDao;
    final entity = _mapToEntity(taskTemplateVariant);

    final id = await taskTemplateVariantDao.insertTaskTemplateVariant(entity);
    taskTemplateVariant.tId = TemplateId.forTaskTemplateVariant(id);

    return taskTemplateVariant;

  }

  static Future<TaskTemplateVariant> update(TaskTemplateVariant taskTemplateVariant) async {

    final database = await getDb();

    final taskTemplateVariantDao = database.taskTemplateVariantDao;
    final entity = _mapToEntity(taskTemplateVariant);

    await taskTemplateVariantDao.updateTaskTemplateVariant(entity);
    return taskTemplateVariant;

  }

  static Future<TaskTemplateVariant> delete(TaskTemplateVariant taskTemplateVariant) async {

    final database = await getDb();

    final taskTemplateVariantDao = database.taskTemplateVariantDao;
    final entity = _mapToEntity(taskTemplateVariant);

    await taskTemplateVariantDao.deleteTaskTemplateVariant(entity);
    return taskTemplateVariant;

  }

  static Future<List<TaskTemplateVariant>> getAllPaged(IdPaging paging) async {
    final database = await getDb();

    final taskTemplateVariantDao = database.taskTemplateVariantDao;
    return taskTemplateVariantDao.findAllPaged(paging.lastId, paging.size)
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<TaskTemplateVariant?> findById(TemplateId tId) async {
    assert(tId.isVariant == true);
    final database = await getDb();

    final taskTemplateVariantDao = database.taskTemplateVariantDao;
    return await taskTemplateVariantDao.findById(tId.id)
        .map((e) => e != null ? _mapFromEntity(e) : null)
        .first;
  }

  static Future<TaskTemplateVariant> getById(TemplateId tId) async {
    assert(tId.isVariant == true);
    final database = await getDb();

    final taskTemplateVariantDao = database.taskTemplateVariantDao;
    return await taskTemplateVariantDao.findById(tId.id)
        .map((e) => _mapFromEntity(e!))
        .first;
  }

  static TaskTemplateVariantEntity _mapToEntity(TaskTemplateVariant taskTemplateVariant) =>
    TaskTemplateVariantEntity(
        taskTemplateVariant.tId?.id,
        taskTemplateVariant.taskGroupId,
        taskTemplateVariant.taskTemplateId,
        taskTemplateVariant.title,
        taskTemplateVariant.description,
        taskTemplateVariant.when?.startAtExactly != null ? timeOfDayToEntity(taskTemplateVariant.when!.startAtExactly!) : null,
        taskTemplateVariant.when?.startAt?.index,
        taskTemplateVariant.when?.durationExactly != null ? durationToEntity(taskTemplateVariant.when!.durationExactly!): null,
        taskTemplateVariant.when?.durationHours?.index,
        taskTemplateVariant.severity?.index,
        taskTemplateVariant.favorite ?? false);

  static TaskTemplateVariant _mapFromEntity(TaskTemplateVariantEntity entity) =>
    TaskTemplateVariant(
        id: entity.id,
        taskGroupId: entity.taskGroupId,
        taskTemplateId: entity.taskTemplateId,
        title: entity.title,
        description: entity.description,
        when: entity.startedAt != null
            || entity.aroundStartedAt != null
            || entity.duration != null
            || entity.aroundDuration != null
            ? When(
                startAtExactly: entity.startedAt != null ? timeOfDayFromEntity(entity.startedAt!) : null,
                startAt: entity.aroundStartedAt != null ? AroundWhenAtDay.values.elementAt(entity.aroundStartedAt!) : null,
                durationExactly: entity.duration != null ? durationFromEntity(entity.duration!) : null,
                durationHours: entity.aroundDuration != null ? AroundDurationHours.values.elementAt(entity.aroundDuration!) : null,
              )
            : null,
        severity: entity.severity != null ? Severity.values.elementAt(entity.severity!) : null,
        favorite: entity.favorite);


  static List<TaskTemplateVariant> _mapFromEntities(List<TaskTemplateVariantEntity> entities) =>
      entities.map(_mapFromEntity).toList();

}
