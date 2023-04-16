import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:personaltasklogger/db/entity/TaskGroupEntity.dart';
import 'package:personaltasklogger/db/repository/SequenceRepository.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';

import '../../util/i18n.dart';
import '../database.dart';

class TaskGroupRepository {
  
  static Future<TaskGroup> save(TaskGroup taskGroup) async {

    // try map texts to i18n keys
    if (taskGroup.isPredefined()) {
      tryWrapI18nForNamedDescription(taskGroup, taskGroup.id!);
    }

    if (taskGroup.id != null) {
      final foundTaskGroup = await findByIdJustDb(taskGroup.id!);
      if (foundTaskGroup != null) {
        return update(taskGroup);
      } else {
        return insert(taskGroup);
      }
    }
    else {
      return insert(taskGroup);
    }

  }

  static Future<TaskGroup> insert(TaskGroup taskGroup) async {

    final database = await getDb();

    final taskGroupDao = database.taskGroupDao;

    if (taskGroup.id == null) {
      int nextId = await SequenceRepository.nextSequenceId(database, "TaskGroupEntity");
      taskGroup.id = nextId;
    }
    final entity = _mapTaskGroupToEntity(taskGroup);

    final id = await taskGroupDao.insertTaskGroup(entity);
    taskGroup.id = id;

    return taskGroup;
  }

  static Future<TaskGroup> update(TaskGroup taskGroup) async {

    final database = await getDb();

    final taskGroupDao = database.taskGroupDao;
    final entity = _mapTaskGroupToEntity(taskGroup);
    await taskGroupDao.updateTaskGroup(entity);

    return taskGroup;
    
  }

  static Future<TaskGroup> delete(TaskGroup taskGroup) async {

    if (taskGroup.isPredefined()) {
      taskGroup = findPredefinedTaskGroupById(taskGroup.id!);
      taskGroup.hidden = true;
      final savedTaskGroup = save(taskGroup);
      debugPrint("$taskGroup soft-deleted");
      return savedTaskGroup;
    }
    else {
      return _delete(taskGroup);
    }
  }

  static Future<TaskGroup> undelete(TaskGroup taskGroup) async {
    taskGroup.hidden = false;
    return save(taskGroup);
  }


  static Future<TaskGroup> _delete(TaskGroup taskGroup) async {

    final database = await getDb();

    final taskGroupDao = database.taskGroupDao;
    final entity = _mapTaskGroupToEntity(taskGroup);

    await taskGroupDao.deleteTaskGroup(entity);
    return taskGroup;
    
  }

  static Future<List<TaskGroup>> getAll(bool inclHidden, [String? dbName]) async {
    final database = await getDb(dbName);

    final taskGroupDao = database.taskGroupDao;
    return taskGroupDao.findAll()
        .then((entities) => _mapTaskGroupsFromEntities(entities))
        .then((dbTaskGroups) {
          Set<TaskGroup> taskGroups = HashSet();
          taskGroups.addAll(dbTaskGroups); // must come first since it may override predefined
          taskGroups.addAll(predefinedTaskGroups);
          final taskGroupList = taskGroups
              .where((element) => inclHidden || !(element.hidden??false))
              .toList()..sort();
    
          return taskGroupList;
        });
  }

  static Future<TaskGroup?> findByIdJustDb(int id) async {
    final database = await getDb();

    final taskGroupDao = database.taskGroupDao;
    return await taskGroupDao
        .findById(id)
        .map((e) => e != null ? _mapTaskGroupFromEntity(e) : null)
        .first;
    
  }

  static Future<TaskGroup?> findById(int id) async {
    final foundInDb = await findByIdJustDb(id);
    if (foundInDb != null) {
      return Future.value(foundInDb);
    }
    if (TaskGroup.isIdPredefined(id)) {
      return findPredefinedTaskGroupById(id);
    }
    return null;
  }

  static TaskGroupEntity _mapTaskGroupToEntity(TaskGroup taskGroup) =>
    TaskGroupEntity(
        taskGroup.id,
        taskGroup.name,
        taskGroup.description,
        taskGroup.colorRGB?.value,
        taskGroup.iconData?.codePoint,
        taskGroup.iconData?.fontFamily,
        taskGroup.iconData?.fontPackage,
        taskGroup.hidden,
    );

  static TaskGroup _mapTaskGroupFromEntity(TaskGroupEntity entity) =>
    TaskGroup(
        id: entity.id,
        i18nName: entity.name,
        description: entity.description,
        colorRGB: entity.colorRGB  != null ? Color(entity.colorRGB!) : null,
        iconData: entity.iconCodePoint  != null 
            ? IconData(entity.iconCodePoint!, 
                fontFamily: entity.iconFontFamily!, 
                fontPackage: entity.iconFontPackage!) 
            : null,
        hidden: entity.hidden,
    );



  static List<TaskGroup> _mapTaskGroupsFromEntities(List<TaskGroupEntity> entities) =>
      entities.map(_mapTaskGroupFromEntity).toList();


  static void tryWrapI18nForNamedDescription(
      TaskGroup modelToChange, int predefinedTaskGroupId) {
    final predefinedTaskGroup = findPredefinedTaskGroupById(predefinedTaskGroupId);

    final wrappedName = tryWrapToI18nKey(modelToChange.name, predefinedTaskGroup.name);
    modelToChange.name = wrappedName;

    if (modelToChange.description != null &&
        predefinedTaskGroup.description != null) {
      final wrappedDescription = tryWrapToI18nKey(
          modelToChange.description!, predefinedTaskGroup.description!);
      modelToChange.description = wrappedDescription;
    }
  }

}

