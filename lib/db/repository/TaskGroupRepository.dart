import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:personaltasklogger/db/entity/TaskGroupEntity.dart';
import 'package:personaltasklogger/db/repository/SequenceRepository.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';

import '../../util/i18n.dart';
import '../database.dart';

class TaskGroupRepository {

  static Map<int, TaskGroup> _taskGroupCache = HashMap();
  
  static Future<TaskGroup> save(TaskGroup taskGroup) async {

    // try map texts to i18n keys
    if (taskGroup.isPredefined()) {
      tryWrapI18nForName(taskGroup, taskGroup.id!);
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

    _setCached(taskGroup.id!, taskGroup);

    return taskGroup;
  }

  static Future<TaskGroup> update(TaskGroup taskGroup) async {

    final database = await getDb();

    final taskGroupDao = database.taskGroupDao;
    final entity = _mapTaskGroupToEntity(taskGroup);
    await taskGroupDao.updateTaskGroup(entity);

    _setCached(taskGroup.id!, taskGroup);

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
    _taskGroupCache.remove(taskGroup);
    return taskGroup;
    
  }

  static _setCached(int id, TaskGroup taskGroup) {
    if (taskGroup.id != deletedDefaultTaskGroupId) {
      _taskGroupCache[id] = taskGroup;
    }
  }

  static TaskGroup findPredefinedTaskGroupById(int id) => predefinedTaskGroups.firstWhere((element) => element.id == id);

  static List<TaskGroup> getAllCached({required bool inclHidden}) {
    return _taskGroupCache.values
        .where((element) => inclHidden || !(element.hidden??false))
        .toList().reversed.toList();  //TODO sort nonpref at last;
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

          taskGroups.forEach((element) {
            _setCached(element.id!, element);
          });
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
      _setCached(id, foundInDb);
      return Future.value(foundInDb);
    }
    if (TaskGroup.isIdPredefined(id)) {
      return findPredefinedTaskGroupById(id);
    }
    return null;
  }

  static TaskGroup findByIdFromCache(int id) {
    final cachedTaskGroup = _taskGroupCache[id];
    if (cachedTaskGroup != null) {
      return cachedTaskGroup;
    }
    else if (TaskGroup.isIdPredefined(id)) {
      return findPredefinedTaskGroupById(id);
    }
    else {
      return deletedDefaultTaskGroup;
    }
  }

  static TaskGroupEntity _mapTaskGroupToEntity(TaskGroup taskGroup) =>
    TaskGroupEntity(
        taskGroup.id,
        taskGroup.name,
        taskGroup.colorRGB?.value,
        taskGroup.iconData?.codePoint,
        taskGroup.iconData?.fontFamily,
        taskGroup.iconData?.fontPackage,
        taskGroup.hidden,
    );

  static TaskGroup _mapTaskGroupFromEntity(TaskGroupEntity entity) =>
    TaskGroup(
        id: entity.id,
        name: entity.name,
        colorRGB: entity.colorRGB  != null ? Color(entity.colorRGB!) : null,
        iconData: entity.iconCodePoint  != null 
            ? IconData(entity.iconCodePoint!, 
                fontFamily: entity.iconFontFamily,
                fontPackage: entity.iconFontPackage)
            : null,
        hidden: entity.hidden,
    );



  static List<TaskGroup> _mapTaskGroupsFromEntities(List<TaskGroupEntity> entities) =>
      entities.map(_mapTaskGroupFromEntity).toList();


  static void tryWrapI18nForName(
      TaskGroup modelToChange, int predefinedTaskGroupId) {
    if (TaskGroup.isIdPredefined(predefinedTaskGroupId)) {
      final predefinedTaskGroup = findPredefinedTaskGroupById(
          predefinedTaskGroupId);

      final wrappedName = tryWrapToI18nKey(
          modelToChange.name, predefinedTaskGroup.name);
      modelToChange.name = wrappedName;
    }
  }

}

