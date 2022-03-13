import 'dart:async';
import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/dao/SequencesDao.dart';
import 'package:personaltasklogger/db/dao/TaskEventDao.dart';
import 'package:personaltasklogger/db/entity/SequencesEntity.dart';
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

@Database(version: 6, entities: [
  TaskEventEntity, TaskTemplateEntity, TaskTemplateVariantEntity, ScheduledTaskEntity, ScheduledTaskEventEntity, SequencesEntity])
abstract class AppDatabase extends FloorDatabase {
  TaskEventDao get taskEventDao;
  TaskTemplateDao get taskTemplateDao;
  TaskTemplateVariantDao get taskTemplateVariantDao;
  ScheduledTaskDao get scheduledTaskDao;
  ScheduledTaskEventDao get scheduledTaskEventDao;
  SequencesDao get sequencesDao;
}

final migration2To3 = new Migration(2, 3,
        (sqflite.Database database) async {
          await database.execute("ALTER TABLE TaskEventEntity ADD COLUMN originTaskTemplateId INTEGER");
          await database.execute("ALTER TABLE TaskEventEntity ADD COLUMN originTaskTemplateVariantId INTEGER");
        });

final migration3To4 = new Migration(3, 4,
        (sqflite.Database database) async {
          await database.execute(
              'CREATE TABLE `TaskTemplateEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, PRIMARY KEY (`id`))');
          await database.execute(
              'CREATE TABLE `TaskTemplateVariantEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `taskTemplateId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        });

final migration4To5 = new Migration(4, 5,
        (sqflite.Database database) async {
      await database.execute("ALTER TABLE TaskTemplateEntity ADD COLUMN `hidden` INTEGER");
      await database.execute("ALTER TABLE TaskTemplateVariantEntity ADD COLUMN `hidden` INTEGER");
    });

final migration5To6 = new Migration(5, 6,
        (sqflite.Database database) async {
      await database.execute('CREATE TABLE `SequencesEntity` (`id` INTEGER, `table` TEXT NOT NULL, `lastId` INTEGER NOT NULL, PRIMARY KEY (`id`))');
      await database.execute("INSERT INTO `SequencesEntity` (`table`, `lastId`) VALUES ('TaskTemplateEntity', 1000)");
      await database.execute("INSERT INTO `SequencesEntity` (`table`, `lastId`) VALUES ('TaskTemplateVariantEntity', 1000)");
    });

Future<AppDatabase> getDb() async => $FloorAppDatabase
    .databaseBuilder('app_database.db')
    .addMigrations([migration2To3])
    .addMigrations([migration3To4])
    .addMigrations([migration4To5])
    .addMigrations([migration5To6])
    .build();
