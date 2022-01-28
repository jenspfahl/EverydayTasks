import 'dart:async';
import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/dao/TaskEventDao.dart';
import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/ScheduledTaskDao.dart';
import 'dao/ScheduledTaskEventDao.dart';
import 'entity/ScheduledTaskEntity.dart';
import 'entity/ScheduledTaskEventEntity.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 3, entities: [TaskEventEntity, ScheduledTaskEntity, ScheduledTaskEventEntity])
abstract class AppDatabase extends FloorDatabase {
  TaskEventDao get taskEventDao;
  ScheduledTaskDao get scheduledTaskDao;
  ScheduledTaskEventDao get scheduledTaskEventDao;
}

Migration migration2To3 = new Migration(2, 3,
        (sqflite.Database database) async {
  database.execute("ALTER TABLE TaskEventEntity ADD COLUMN originTaskTemplateId INTEGER");
  database.execute("ALTER TABLE TaskEventEntity ADD COLUMN originTaskTemplateVariantId INTEGER");
});

Future<AppDatabase> getDb() async => $FloorAppDatabase
    .databaseBuilder('app_database.db')
    .addMigrations([migration2To3])
    .build();
