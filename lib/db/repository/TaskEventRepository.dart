import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import '../database.dart';
import 'mapper.dart';

class TaskEventRepository {
  static Future<void> insert(TaskEvent taskEvent) async {

    final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();

    final taskEventDao = database.taskEventDao;
    final entity = _mapToEntity(taskEvent);

    await taskEventDao.insertTaskEvent(entity);

  }

  static Future<List<TaskEvent>> getAll() async {

    final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();

    final taskEventDao = database.taskEventDao;
    return await taskEventDao.findAll()
        .map((e) => _mapFromEntity(e!))
        .toList();
  }

  static Future<TaskEvent> getById(int id) async {

    final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();

    final taskEventDao = database.taskEventDao;
    return await taskEventDao.findById(id)
        .map((e) => _mapFromEntity(e!))
        .first;
  }

  static TaskEventEntity _mapToEntity(TaskEvent taskEvent) =>
    TaskEventEntity(
        taskEvent.id,
        taskEvent.name,
        taskEvent.description,
        taskEvent.originTaskGroup,
        taskEvent.colorRGB,
        dateTimeToEntity(taskEvent.startedAt),
        dateTimeToEntity(taskEvent.finishedAt),
        taskEvent.severity.index,
        taskEvent.favorite);

  static TaskEvent _mapFromEntity(TaskEventEntity entity) =>
    TaskEvent(
        entity.id,
        entity.name,
        entity.description,
        entity.originTaskGroup,
        entity.colorRGB,
        dateTimeFromEntity(entity.startedAt),
        dateTimeFromEntity(entity.finishedAt),
        Severity.values.elementAt(entity.severity),
        entity.favorite);
  
}
