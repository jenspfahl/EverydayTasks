import 'dart:ui';

import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';
import 'package:personaltasklogger/db/repository/IdPaging.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/model/When.dart';
import '../database.dart';
import 'ChronologicalPaging.dart';
import 'mapper.dart';

class TaskTemplateRepository {

  static Future<TaskTemplate> insert(TaskTemplate taskTemplate) async {

    final database = await getDb();

    final taskTemplateDao = database.taskTemplateDao;
    final entity = _mapToEntity(taskTemplate);

    final id = await taskTemplateDao.insertTaskTemplate(entity);
    taskTemplate.tId = TemplateId.forTaskTemplate(id);

    return taskTemplate;

  }

  static Future<TaskTemplate> update(TaskTemplate taskTemplate) async {

    final database = await getDb();

    final taskTemplateDao = database.taskTemplateDao;
    final entity = _mapToEntity(taskTemplate);

    await taskTemplateDao.updateTaskTemplate(entity);
    return taskTemplate;

  }

  static Future<TaskTemplate> delete(TaskTemplate taskTemplate) async {

    final database = await getDb();

    final taskTemplateDao = database.taskTemplateDao;
    final entity = _mapToEntity(taskTemplate);

    await taskTemplateDao.deleteTaskTemplate(entity);
    return taskTemplate;

  }

  static Future<List<TaskTemplate>> getAllPaged(IdPaging paging) async {
    final database = await getDb();

    final taskTemplateDao = database.taskTemplateDao;
    return taskTemplateDao.findAllPaged(paging.lastId, paging.size)
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<List<TaskTemplate>> getAllFavsPaged(IdPaging paging) async {
    final database = await getDb();

    final taskTemplateDao = database.taskTemplateDao;
    return taskTemplateDao.findAllFavsPaged(paging.lastId, paging.size)
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<TaskTemplate?> findById(TemplateId tId) async {
    assert(tId.isVariant == false);
    final database = await getDb();

    final taskTemplateDao = database.taskTemplateDao;
    return await taskTemplateDao.findById(tId.id)
        .map((e) => e != null ? _mapFromEntity(e) : null)
        .first;
  }

  static Future<TaskTemplate> getById(TemplateId tId) async {
    assert(tId.isVariant == false);
    final database = await getDb();

    final taskTemplateDao = database.taskTemplateDao;
    return await taskTemplateDao.findById(tId.id)
        .map((e) => _mapFromEntity(e!))
        .first;
  }

  static TaskTemplateEntity _mapToEntity(TaskTemplate taskTemplate) =>
    TaskTemplateEntity(
        taskTemplate.tId?.id,
        taskTemplate.taskGroupId,
        taskTemplate.title,
        taskTemplate.description,
        taskTemplate.when?.startAtExactly != null ? timeOfDayToEntity(taskTemplate.when!.startAtExactly!) : null,
        taskTemplate.when?.startAt?.index,
        taskTemplate.when?.durationExactly != null ? durationToEntity(taskTemplate.when!.durationExactly!): null,
        taskTemplate.when?.durationHours?.index,
        taskTemplate.severity?.index,
        taskTemplate.favorite ?? false);

  static TaskTemplate _mapFromEntity(TaskTemplateEntity entity) =>
    TaskTemplate(
        id: entity.id,
        taskGroupId: entity.taskGroupId,
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


  static List<TaskTemplate> _mapFromEntities(List<TaskTemplateEntity> entities) =>
      entities.map(_mapFromEntity).toList();

}
