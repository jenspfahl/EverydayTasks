import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import '../database.dart';
import 'ChronologicalPaging.dart';
import 'mapper.dart';

class TaskEventRepository {

  static Future<TaskEvent> insert(TaskEvent taskEvent) async {

    final database = await getDb();

    final taskEventDao = database.taskEventDao;
    final entity = _mapToEntity(taskEvent);

    final id = await taskEventDao.insertTaskEvent(entity);
    taskEvent.id = id;

    return taskEvent;

  }

  static Future<TaskEvent> update(TaskEvent taskEvent) async {

    final database = await getDb();

    final taskEventDao = database.taskEventDao;
    final entity = _mapToEntity(taskEvent);

    await taskEventDao.updateTaskEvent(entity);
    return taskEvent;

  }

  static Future<TaskEvent> delete(TaskEvent taskEvent) async {

    final database = await getDb();

    final taskEventDao = database.taskEventDao;
    final entity = _mapToEntity(taskEvent);

    await taskEventDao.deleteTaskEvent(entity);
    return taskEvent;

  }

  static Future<List<TaskEvent>> getAllPaged(ChronologicalPaging paging) async {
    final database = await getDb();

    final taskEventDao = database.taskEventDao;
    return taskEventDao.findAllBeginningByStartedAt(
        paging.lastDateTime.millisecondsSinceEpoch, paging.lastId, paging.size)
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<TaskEvent> getById(int id) async {

    final database = await getDb();

    final taskEventDao = database.taskEventDao;
    return await taskEventDao.findById(id)
        .map((e) => _mapFromEntity(e!))
        .first;
  }

  static TaskEventEntity _mapToEntity(TaskEvent taskEvent) =>
    TaskEventEntity(
        taskEvent.id,
        taskEvent.taskGroupId,
        taskEvent.name,
        taskEvent.description,
        taskEvent.colorRGB,
        dateTimeToEntity(taskEvent.startedAt),
        dateTimeToEntity(taskEvent.finishedAt),
        taskEvent.severity.index,
        taskEvent.favorite);

  static TaskEvent _mapFromEntity(TaskEventEntity entity) =>
    TaskEvent(
        entity.id,
        entity.taskGroupId,
        entity.name,
        entity.description,
        entity.colorRGB,
        dateTimeFromEntity(entity.startedAt),
        dateTimeFromEntity(entity.finishedAt),
        Severity.values.elementAt(entity.severity),
        entity.favorite);


  static List<TaskEvent> _mapFromEntities(List<TaskEventEntity> entities) =>
      entities.map(_mapFromEntity).toList();

  static Future<AppDatabase> getDb() async =>
      $FloorAppDatabase.databaseBuilder('app_database.db').build();

}
