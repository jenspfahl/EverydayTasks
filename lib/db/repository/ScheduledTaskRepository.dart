
import 'package:personaltasklogger/db/entity/ScheduledTaskEntity.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/model/When.dart';

import '../database.dart';
import 'ChronologicalPaging.dart';
import 'mapper.dart';

class ScheduledTaskRepository {

  static Future<ScheduledTask> insert(ScheduledTask scheduledTask) async {

    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    final entity = _mapToEntity(scheduledTask);

    final id = await scheduledTaskDao.insertScheduledTask(entity);
    scheduledTask.id = id;

    if (scheduledTask.templateId != null) {
      TemplateRepository.cacheParentFor(scheduledTask.templateId!);
    }

    return scheduledTask;

  }

  static Future<ScheduledTask> update(ScheduledTask scheduledTask) async {

    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    final entity = _mapToEntity(scheduledTask);

    await scheduledTaskDao.updateScheduledTask(entity);
    return scheduledTask;

  }

  static Future<ScheduledTask> delete(ScheduledTask scheduledTask) async {

    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    final entity = _mapToEntity(scheduledTask);

    await scheduledTaskDao.deleteScheduledTask(entity);
    return scheduledTask;

  }

  static Future<List<ScheduledTask>> getAllPaged(ChronologicalPaging paging) async {
    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    return scheduledTaskDao.findAll()
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<List<ScheduledTask>> getByTemplateId(TemplateId templateId) async {
    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    return (templateId.isVariant
        ? scheduledTaskDao.findByTaskTemplateVariantId(templateId.id)
        : scheduledTaskDao.findByTaskTemplateId(templateId.id))
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<ScheduledTask?> findById(int id) async {

    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    return await scheduledTaskDao.findById(id)
        .map((e) => e != null ? _mapFromEntity(e) : null)
        .first;
  }

  static ScheduledTaskEntity _mapToEntity(ScheduledTask scheduledTask) =>
    ScheduledTaskEntity(
        scheduledTask.id,
        scheduledTask.taskGroupId,
        scheduledTask.templateId?.taskTemplateId,
        scheduledTask.templateId?.taskTemplateVariantId,
        scheduledTask.title,
        scheduledTask.description,
        dateTimeToEntity(scheduledTask.createdAt),
        scheduledTask.schedule.aroundStartAt.index,
        scheduledTask.schedule.startAtExactly != null ? timeOfDayToEntity(scheduledTask.schedule.startAtExactly!) : null,
        scheduledTask.schedule.repetitionStep.index,
        scheduledTask.schedule.customRepetition?.repetitionValue,
        scheduledTask.schedule.customRepetition?.repetitionUnit.index,
        scheduledTask.lastScheduledEventOn != null ? dateTimeToEntity(scheduledTask.lastScheduledEventOn!) : null,
        scheduledTask.active,
        scheduledTask.pausedAt != null ? dateTimeToEntity(scheduledTask.pausedAt!) : null,
    );

  static ScheduledTask _mapFromEntity(ScheduledTaskEntity entity) {
    final scheduledTask = ScheduledTask(
        id: entity.id,
        taskGroupId: entity.taskGroupId,
        templateId: entity.taskTemplateId != null
            ? new TemplateId.forTaskTemplate(entity.taskTemplateId!)
            : entity.taskTemplateVariantId != null
                ? new TemplateId.forTaskTemplateVariant(entity.taskTemplateVariantId!)
                : null,
        title: entity.title,
        description: entity.description,
        createdAt: dateTimeFromEntity(entity.createdAt),
        schedule: Schedule(
          aroundStartAt: AroundWhenAtDay.values.elementAt(entity.aroundStartAt),
          startAtExactly: entity.startAt != null ? timeOfDayFromEntity(entity.startAt!) : null,
          repetitionStep: RepetitionStep.values.elementAt(entity.repetitionAfter),
          customRepetition: entity.exactRepetitionAfter != null && entity.exactRepetitionAfterUnit != null
              ? CustomRepetition(entity.exactRepetitionAfter!, RepetitionUnit.values.elementAt(entity.exactRepetitionAfterUnit!) )
              : null,
        ),
        lastScheduledEventOn: entity.lastScheduledEventAt != null ? dateTimeFromEntity(entity.lastScheduledEventAt!) : null,
        active: entity.active,
        pausedAt: entity.pausedAt != null ? dateTimeFromEntity(entity.pausedAt!) : null,
    );

    if (scheduledTask.templateId != null) {
      TemplateRepository.cacheParentFor(scheduledTask.templateId!);
    }

    return scheduledTask;
  }


  static List<ScheduledTask> _mapFromEntities(List<ScheduledTaskEntity> entities) =>
      entities.map(_mapFromEntity).toList();

}
