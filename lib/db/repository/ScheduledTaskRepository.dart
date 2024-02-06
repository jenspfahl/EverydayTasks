
import 'package:personaltasklogger/db/dao/ScheduledTaskFixedScheduleDao.dart';
import 'package:personaltasklogger/db/entity/ScheduledTaskEntity.dart';
import 'package:personaltasklogger/db/entity/ScheduledTaskFixedScheduleEntity.dart';
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

    // try map texts to i18n keys
    if (scheduledTask.templateId?.isPredefined()??false) {
      tryWrapI18nForTitleAndDescription(scheduledTask, scheduledTask.templateId!);
    }

    final scheduledTaskDao = database.scheduledTaskDao;
    final entity = _mapToEntity(scheduledTask);

    final id = await scheduledTaskDao.insertScheduledTask(entity);
    scheduledTask.id = id;

    if (scheduledTask.templateId != null) {
      TemplateRepository.cacheParentFor(scheduledTask.templateId!);
    }

    final scheduledTaskFixedScheduleDao = database.scheduledTaskFixedScheduleDao;
    _insertMappedFixedSchedules(scheduledTask, scheduledTaskFixedScheduleDao);


    return scheduledTask;

  }

  static Future<ScheduledTask> update(ScheduledTask scheduledTask) async {

    final database = await getDb();

    // try map texts to i18n keys
    if (scheduledTask.templateId?.isPredefined()??false) {
      tryWrapI18nForTitleAndDescription(scheduledTask, scheduledTask.templateId!);
    }
    
    final scheduledTaskDao = database.scheduledTaskDao;
    final entity = _mapToEntity(scheduledTask);

    await scheduledTaskDao.updateScheduledTask(entity);

    final scheduledTaskFixedScheduleDao = database.scheduledTaskFixedScheduleDao;
    scheduledTaskFixedScheduleDao.deleteFixedScheduleByScheduledTaskId(scheduledTask.id!);
    _insertMappedFixedSchedules(scheduledTask, scheduledTaskFixedScheduleDao);
    
    
    return scheduledTask;

  }

  static void _insertMappedFixedSchedules(ScheduledTask scheduledTask, ScheduledTaskFixedScheduleDao scheduledTaskFixedScheduleDao) {
    scheduledTask.schedule.weekBasedSchedules.forEach((dayOfWeek) {
      scheduledTaskFixedScheduleDao.insertFixedSchedule(_createWeekBasedFixedScheduleToEntity(scheduledTask.id!, dayOfWeek));
    });
    
    scheduledTask.schedule.monthBasedSchedules.forEach((dayOfMonth) {
      scheduledTaskFixedScheduleDao.insertFixedSchedule(_createMonthBasedFixedScheduleToEntity(scheduledTask.id!, dayOfMonth));
    });
    
    scheduledTask.schedule.yearBasedSchedules.forEach((allYearDate) {
      scheduledTaskFixedScheduleDao.insertFixedSchedule(_createYearBasedFixedScheduleToEntity(scheduledTask.id!, allYearDate));
    });
  }

  static Future<ScheduledTask> delete(ScheduledTask scheduledTask) async {

    final database = await getDb();

    final scheduledTaskFixedScheduleDao = database.scheduledTaskFixedScheduleDao;
    scheduledTaskFixedScheduleDao.deleteFixedScheduleByScheduledTaskId(scheduledTask.id!);

    final scheduledTaskDao = database.scheduledTaskDao;
    final entity = _mapToEntity(scheduledTask);

    await scheduledTaskDao.deleteScheduledTask(entity);
    return scheduledTask;

  }

  static Future<List<ScheduledTask>> getAllPaged(ChronologicalPaging paging, [String? dbName]) async {
    final database = await getDb(dbName);

    final scheduledTaskDao = database.scheduledTaskDao;
    final list = await  scheduledTaskDao.findAll()
        .then((entities) => _mapFromEntities(entities));
    
    return _addFixedSchedules(list, database);
  }

  static Future<int?> countDue([String? dbName]) async {
    final database = await getDb(dbName);

    final scheduledTaskDao = database.scheduledTaskDao;
    return scheduledTaskDao.findAll()
        .then((entities) => entities
          .where((e) => e.active)
          .where((e) => e.pausedAt == null)
          .map((e) => _mapFromEntity(e))
          .where((e) => e.isDueNow() || e.isNextScheduleOverdue(false))
          .length);
  }

  static Future<List<ScheduledTask>> getByTemplateId(TemplateId templateId) async {
    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    return (templateId.isVariant
        ? scheduledTaskDao.findByTaskTemplateVariantId(templateId.id)
        : scheduledTaskDao.findByTaskTemplateId(templateId.id))
        .then((entities) => _addFixedSchedules(_mapFromEntities(entities), database));
  }

  static Future<ScheduledTask?> findById(int id) async {

    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    final scheduledTask = await scheduledTaskDao.findById(id)
        .map((e) => e != null ? _mapFromEntity(e) : null)
        .first;

    if (scheduledTask == null) {
      return null;
    }

    final scheduledTaskFixedScheduleDao = database.scheduledTaskFixedScheduleDao;
    final fixedSchedules = await scheduledTaskFixedScheduleDao.findByScheduledTaskId(scheduledTask.id!);
    fixedSchedules.forEach((fixedSchedule) {
      final type = FixedScheduleType.values[fixedSchedule.type];
      mapFixedSchedules(scheduledTask.schedule, type, fixedSchedule.value);
    });
    return scheduledTask;
  }

  static Future<int?> countByTaskGroupId(int taskGroupId) async {

    final database = await getDb();

    final scheduledTaskDao = database.scheduledTaskDao;
    return await scheduledTaskDao.countByTaskGroupId(taskGroupId).first;
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
        scheduledTask.important,
        scheduledTask.pausedAt != null ? dateTimeToEntity(scheduledTask.pausedAt!) : null,
        scheduledTask.schedule.repetitionMode.index,
        scheduledTask.reminderNotificationEnabled,
        scheduledTask.reminderNotificationRepetition?.repetitionValue,
        scheduledTask.reminderNotificationRepetition?.repetitionUnit.index,
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
          repetitionMode: entity.repetitionMode != null
              ? RepetitionMode.values.elementAt(entity.repetitionMode!)
              : RepetitionMode.DYNAMIC,
        ),
        lastScheduledEventOn: entity.lastScheduledEventAt != null ? dateTimeFromEntity(entity.lastScheduledEventAt!) : null,
        active: entity.active,
        important: entity.important ?? false,
        pausedAt: entity.pausedAt != null ? dateTimeFromEntity(entity.pausedAt!) : null,
        reminderNotificationEnabled: entity.reminderNotificationEnabled,
        reminderNotificationRepetition: entity.reminderNotificationPeriod != null  && entity.reminderNotificationUnit != null
            ? CustomRepetition(entity.reminderNotificationPeriod!, RepetitionUnit.values.elementAt(entity.reminderNotificationUnit!) )
            : null,
    );

    if (scheduledTask.templateId != null) {
      TemplateRepository.cacheParentFor(scheduledTask.templateId!);
    }

    return scheduledTask;
  }


  static Iterable<ScheduledTask> _mapFromEntities(List<ScheduledTaskEntity> entities) =>
      entities.map(_mapFromEntity);

  static void mapFixedSchedules(Schedule schedule, FixedScheduleType type, int value) {
    switch (type) {
      case FixedScheduleType.WEEK_BASED : {
        schedule.weekBasedSchedules.add(DayOfWeek.values[value]);
        break;
      }
      case FixedScheduleType.MONTH_BASED : {
        schedule.monthBasedSchedules.add(value);
        break;
      }
      case FixedScheduleType.YEAR_BASED : {
        schedule.yearBasedSchedules.add(AllYearDate.fromValue(value));
        break;
      }
    }
  }

  static Future<List<ScheduledTask>> _addFixedSchedules(Iterable<ScheduledTask> scheduledTasks, AppDatabase database) {
    final scheduledTaskFixedScheduleDao = database.scheduledTaskFixedScheduleDao;
    final list = scheduledTasks.map((scheduledTask) async {
      final fixedSchedules = await scheduledTaskFixedScheduleDao.findByScheduledTaskId(scheduledTask.id!);
      return _mapFixedSchedules(scheduledTask, fixedSchedules);
    });
    
    return Future.wait(list);

  }

  static ScheduledTask _mapFixedSchedules(ScheduledTask scheduledTask, List<ScheduledTaskFixedScheduleEntity> fixedSchedules) {
    fixedSchedules.forEach((fixedSchedule) {
       final type = FixedScheduleType.values[fixedSchedule.type];
       mapFixedSchedules(scheduledTask.schedule, type, fixedSchedule.value);
    });
  
    return scheduledTask;
  }

  static ScheduledTaskFixedScheduleEntity _createWeekBasedFixedScheduleToEntity(int scheduledTaskId, DayOfWeek dayOfWeek) {
    return ScheduledTaskFixedScheduleEntity(null, scheduledTaskId, FixedScheduleType.WEEK_BASED.index, dayOfWeek.index);
  }

  static ScheduledTaskFixedScheduleEntity _createMonthBasedFixedScheduleToEntity(int scheduledTaskId, int dayOfMonth) {
    return ScheduledTaskFixedScheduleEntity(null, scheduledTaskId, FixedScheduleType.MONTH_BASED.index, dayOfMonth);
  }

  static ScheduledTaskFixedScheduleEntity _createYearBasedFixedScheduleToEntity(int scheduledTaskId, AllYearDate allYearDate) {
    return ScheduledTaskFixedScheduleEntity(null, scheduledTaskId, FixedScheduleType.YEAR_BASED.index, allYearDate.value);
  }

}
