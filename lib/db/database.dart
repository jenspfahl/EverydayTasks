import 'dart:async';
import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/dao/TaskEventDao.dart';
import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateVariantEntity.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/ScheduledTaskDao.dart';
import 'dao/ScheduledTaskEventDao.dart';
import 'dao/TaskTemplateDao.dart';
import 'dao/TaskTemplateVariantDao.dart';
import 'entity/ScheduledTaskEntity.dart';
import 'entity/ScheduledTaskEventEntity.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 4, entities: [
  TaskEventEntity, TaskTemplateEntity, TaskTemplateVariantEntity, ScheduledTaskEntity, ScheduledTaskEventEntity])
abstract class AppDatabase extends FloorDatabase {
  TaskEventDao get taskEventDao;
  TaskTemplateDao get taskTemplateDao;
  TaskTemplateVariantDao get taskTemplateVariantDao;
  ScheduledTaskDao get scheduledTaskDao;
  ScheduledTaskEventDao get scheduledTaskEventDao;
}

final migration2To3 = new Migration(2, 3,
        (sqflite.Database database) async {
          await database.execute("ALTER TABLE TaskEventEntity ADD COLUMN originTaskTemplateId INTEGER");
          await database.execute("ALTER TABLE TaskEventEntity ADD COLUMN originTaskTemplateVariantId INTEGER");
        });

final migration3To4 = new Migration(3, 4,
        (sqflite.Database database) async {
          await database.execute(
              'CREATE TABLE IF NOT EXISTS `TaskTemplateEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, PRIMARY KEY (`id`))');
          await database.execute(
              'CREATE TABLE IF NOT EXISTS `TaskTemplateVariantEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `taskTemplateId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        });

Future<AppDatabase> getDb() async => $FloorAppDatabase
    .databaseBuilder('app_database.db')
    .addMigrations([migration2To3])
    .addMigrations([migration3To4])
    .build();
