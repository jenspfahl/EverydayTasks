
import 'package:personaltasklogger/db/entity/ScheduledTaskEventEntity.dart';
import 'package:personaltasklogger/model/ScheduledTaskEvent.dart';

import '../database.dart';
import 'ChronologicalPaging.dart';
import 'mapper.dart';

class ScheduledTaskEventRepository {

  static Future<ScheduledTaskEvent> insert(ScheduledTaskEvent scheduledTaskEvent) async {

    final database = await getDb();

    final scheduledTaskEventDao = database.scheduledTaskEventDao;
    final entity = _mapToEntity(scheduledTaskEvent);

    final id = await scheduledTaskEventDao.insertScheduledTaskEvent(entity);
    scheduledTaskEvent.id = id;

    return scheduledTaskEvent;

  }

  static Future<ScheduledTaskEvent> update(ScheduledTaskEvent scheduledTaskEvent) async {

    final database = await getDb();

    final scheduledTaskEventDao = database.scheduledTaskEventDao;
    final entity = _mapToEntity(scheduledTaskEvent);

    await scheduledTaskEventDao.updateScheduledTaskEvent(entity);
    return scheduledTaskEvent;

  }

  static Future<ScheduledTaskEvent> delete(ScheduledTaskEvent scheduledTaskEvent) async {

    final database = await getDb();

    final scheduledTaskEventDao = database.scheduledTaskEventDao;
    final entity = _mapToEntity(scheduledTaskEvent);

    await scheduledTaskEventDao.deleteScheduledTaskEvent(entity);
    return scheduledTaskEvent;

  }

  static Future<List<ScheduledTaskEvent>> getByScheduledTaskIdPaged(scheduledTaskId, ChronologicalPaging paging) async {
    final database = await getDb();

    final scheduledTaskEventDao = database.scheduledTaskEventDao;
    return scheduledTaskEventDao.findByScheduledTaskId(scheduledTaskId, paging.lastId, paging.size)
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<List<ScheduledTaskEvent>> findByTaskEventId(taskEventId, [String? dbName]) async {
    final database = await getDb(dbName);

    final scheduledTaskEventDao = database.scheduledTaskEventDao;
    return scheduledTaskEventDao.findByTaskEventId(taskEventId)
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<ScheduledTaskEvent> getById(int id) async {

    final database = await getDb();

    final scheduledTaskEventDao = database.scheduledTaskEventDao;
    return await scheduledTaskEventDao.findById(id)
        .map((e) => _mapFromEntity(e!))
        .first;
  }

  static ScheduledTaskEventEntity _mapToEntity(ScheduledTaskEvent scheduledTaskEvent) =>
    ScheduledTaskEventEntity(
        scheduledTaskEvent.id,
        scheduledTaskEvent.taskEventId,
        scheduledTaskEvent.scheduledTaskId,
        dateTimeToEntity(scheduledTaskEvent.createdAt),
        );

  static ScheduledTaskEvent _mapFromEntity(ScheduledTaskEventEntity entity) =>
    ScheduledTaskEvent(
        entity.id,
        entity.taskEventId,
        entity.scheduledTaskId,
        dateTimeFromEntity(entity.createdAt),
       );


  static List<ScheduledTaskEvent> _mapFromEntities(List<ScheduledTaskEventEntity> entities) =>
      entities.map(_mapFromEntity).toList();

}
