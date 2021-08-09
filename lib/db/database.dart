import 'dart:async';
import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/dao/TaskEventDao.dart';
import 'package:personaltasklogger/db/entity/TaskEventEntity.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'database.g.dart'; // the generated code will be there

@Database(version: 2, entities: [TaskEventEntity])
abstract class AppDatabase extends FloorDatabase {
  TaskEventDao get taskEventDao;
}

Future<AppDatabase> getDb() async => $FloorAppDatabase
    .databaseBuilder('app_database.db')
    .build();
