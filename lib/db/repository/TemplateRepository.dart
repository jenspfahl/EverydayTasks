import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateVariantEntity.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/model/TaskTemplateVariant.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/model/When.dart';

import '../database.dart';
import 'mapper.dart';

class TemplateRepository {

  static Future<Template> save(Template template) async {
    if (template.tId != null) {
      final foundTemplate = await findByIdJustDb(template.tId!);
      if (foundTemplate != null) {
        return update(template);
      } else {
        return insert(template);
      }
    }
    else {
      return insert(template);
    }

  }

  static Future<Template> insert(Template template) async {

    final database = await getDb();

    if (template is TaskTemplate) {
      final taskTemplateDao = database.taskTemplateDao;

      if (template.tId == null) {
        int? maxId = await taskTemplateDao.findMaxId();
        maxId = _incId(maxId);
        template.tId = TemplateId.forTaskTemplate(maxId);
      }
      final entity = _mapTemplateToEntity(template);

      final id = await taskTemplateDao.insertTaskTemplate(entity);
      template.tId = TemplateId.forTaskTemplate(id);

      return template;
    }
    else if (template is TaskTemplateVariant) {
      final taskTemplateVariantDao = database.taskTemplateVariantDao;

      if (template.tId == null) {
        int maxId = await taskTemplateVariantDao.findMaxId() ?? 0;
        maxId = _incId(maxId);
        template.tId = TemplateId.forTaskTemplateVariant(maxId);
      }

      final entity = _mapTemplateVariantToEntity(template);

      final id = await taskTemplateVariantDao.insertTaskTemplateVariant(entity);
      template.tId = TemplateId.forTaskTemplateVariant(id);

      return template;
    }
    throw Exception("unsupported template");
  }

  static Future<Template> update(Template template) async {

    final database = await getDb();

    if (template is TaskTemplate) {
      final taskTemplateDao = database.taskTemplateDao;
      final entity = _mapTemplateToEntity(template);
      await taskTemplateDao.updateTaskTemplate(entity);

      return template;
    }
    else if (template is TaskTemplateVariant) {
      final taskTemplateVariantDao = database.taskTemplateVariantDao;
      final entity = _mapTemplateVariantToEntity(template);

      await taskTemplateVariantDao.updateTaskTemplateVariant(entity);

      return template;
    }
    throw Exception("unsupported template");
  }

  static Future<Template> delete(Template template) async {
    if (template.isPredefined()) {
      template.hidden = true;
      final savedTemplate = save(template);
      debugPrint("$template soft-deleted");
      return savedTemplate;
    }
    else {
      return _delete(template);
    }
  }

  static Future<Template> undelete(Template template) async {
    template.hidden = false;
    return save(template);
  }


  static Future<Template> _delete(Template template) async {

    final database = await getDb();

    if (template is TaskTemplate) {
      final taskTemplateDao = database.taskTemplateDao;
      final entity = _mapTemplateToEntity(template);

      await taskTemplateDao.deleteTaskTemplate(entity);
      return template;
    }
    else if (template is TaskTemplateVariant) {
      final taskTemplateVariantDao = database.taskTemplateVariantDao;
      final entity = _mapTemplateVariantToEntity(template);

      await taskTemplateVariantDao.deleteTaskTemplateVariant(entity);
      return template;
    }
    throw Exception("unsupported template");
  }

  static Future<List<TaskTemplate>> getAllTaskTemplates(bool showHidden) async {
    final database = await getDb();

    final taskTemplateDao = database.taskTemplateDao;
    return taskTemplateDao.findAll()
        .then((entities) => _mapTemplatesFromEntities(entities))
        .then((dbTemplates) {
          Set<TaskTemplate> templates = HashSet();
          templates.addAll(dbTemplates); // must come first since it may override predefined
          templates.addAll(predefinedTaskTemplates);
          final templateList = templates
              .where((element) => showHidden ? true : !(element.hidden??false))
              .toList()..sort();
    
          return templateList;
        });
  }

  static Future<List<TaskTemplateVariant>> getAllTaskTemplateVariants(bool showHidden) async {
    final database = await getDb();

    final taskTemplateVariantDao = database.taskTemplateVariantDao;
    return taskTemplateVariantDao.findAll()
        .then((entities) => _mapTemplateVariantsFromEntities(entities))
        .then((dbTemplateVariants) {
          Set<TaskTemplateVariant> templates = HashSet();
          templates.addAll(dbTemplateVariants); // must come first since it may override predefined
          templates.addAll(predefinedTaskTemplateVariants);
          final templateList = templates
              .where((element) => showHidden ? true : !(element.hidden??false))
              .toList()..sort();
    
          return templateList;
        });
  }

  static Future<List<Template>> getAll(bool showHidden) async {
    final taskTemplatesFuture = getAllTaskTemplates(showHidden);
    final taskTemplateVariantsFuture = getAllTaskTemplateVariants(showHidden);
    final taskTemplates = await taskTemplatesFuture;
    final taskTemplateVariants = await taskTemplateVariantsFuture;

    List<Template> templates = [];
    templates.addAll(taskTemplates);
    templates.addAll(taskTemplateVariants);
    return Future.value(templates);
  }

  static Future<List<Template>> getAllFavorites() async {
    return getAll(false)
        .then((list) => list
          .where((template) => (template.favorite??false))
        .toList());
  }

  static Future<Template?> findByIdJustDb(TemplateId tId) async {
    final database = await getDb();

    if (tId.isVariant) {
      final taskTemplateVariantDao = database.taskTemplateVariantDao;
      return await taskTemplateVariantDao
          .findById(tId.id)
          .map((e) => e != null ? _mapTemplateVariantFromEntity(e) : null)
          .first;
    }
    else {
      final taskTemplateDao = database.taskTemplateDao;
      return await taskTemplateDao
          .findById(tId.id)
          .map((e) => e != null ? _mapTemplateFromEntity(e) : null)
          .first;
    }
  }

  static Future<Template> getById(TemplateId tId) async {
    final foundInDb = await findByIdJustDb(tId);
    if (foundInDb != null) {
      return Future.value(foundInDb);
    }
    return findPredefinedTemplate(tId);
  }

  static Template findPredefinedTemplate(TemplateId tId) {
    if (tId.isVariant) {
      return predefinedTaskTemplateVariants.firstWhere((variant) => variant.tId == tId);
    }
    else {
      return predefinedTaskTemplates.firstWhere((template) => template.tId == tId);
    }
  }

  static TaskTemplateEntity _mapTemplateToEntity(TaskTemplate taskTemplate) =>
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
        taskTemplate.favorite ?? false,
        taskTemplate.hidden,
    );

  static TaskTemplate _mapTemplateFromEntity(TaskTemplateEntity entity) =>
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
        favorite: entity.favorite,
        hidden: entity.hidden,
    );



  static List<TaskTemplate> _mapTemplatesFromEntities(List<TaskTemplateEntity> entities) =>
      entities.map(_mapTemplateFromEntity).toList();


  static TaskTemplateVariantEntity _mapTemplateVariantToEntity(TaskTemplateVariant taskTemplateVariant) =>
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
          taskTemplateVariant.favorite ?? false,
          taskTemplateVariant.hidden,
      );

  static TaskTemplateVariant _mapTemplateVariantFromEntity(TaskTemplateVariantEntity entity) =>
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
          favorite: entity.favorite,
          hidden: entity.hidden,
      );


  static List<TaskTemplateVariant> _mapTemplateVariantsFromEntities(List<TaskTemplateVariantEntity> entities) =>
      entities.map(_mapTemplateVariantFromEntity).toList();



  static int _incId(int? maxId) {
    if (maxId == null || maxId < 0) {
      maxId = 0;
    }
    return maxId + 1;
  }

}
