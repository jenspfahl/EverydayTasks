import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personaltasklogger/db/repository/ChronologicalPaging.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database.dart';
import '../db/repository/TemplateRepository.dart';

class BackupRestoreService {
  static final BackupRestoreService _service = BackupRestoreService._internal();

  factory BackupRestoreService() {
    return _service;
  }

  BackupRestoreService._internal();

  Future<void> backup(Function(bool, String?) successHandler, Function(String) errorHandler) async {
    try {
      final dbFolder = await getDatabasesPath();
      final srcFile = File("$dbFolder/app_database.db");

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = "EverydayTasks_$today.db";

      final savedPath = await FilePicker.saveFile(
          fileName: fileName,
          allowedExtensions: ["db"],
          bytes: srcFile.readAsBytesSync(),
      );
      if (savedPath != null) {
        successHandler(true, fileName);
      } else {
        successHandler(false, null);
      }
    } on FileSystemException catch (e) {
      errorHandler("Cannot export database! " + e.message);
      print(e);
    } catch (e) {
      errorHandler("Cannot export database!");
      print(e);
    }

  }

  Future<void> restore(Function(bool) successHandler, Function(String) errorHandler) async {

    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'app_database.db');
      final dbJournalPath = join(dbFolder, 'app_database.db-journal');
      final restoreDbPath = join(dbFolder, 'restore_app_database.db');

      final result = await FilePicker.pickFiles();

      if (result != null) {
        File? restoreDbFile;
        Database? dbToRestore;
        try {
          final source = File(result.files.single.path!);
          debugPrint("file to take from: ${source.path}");

          // copy restore to internal folder
          restoreDbFile = await source.copy(restoreDbPath);
          debugPrint("file to restore: ${restoreDbFile.path}");

          // open file and try to read
          dbToRestore = await openDatabase(restoreDbFile.path, readOnly: true);
          final dbToRestoreName = dbToRestore.path;

          // do a test if it is a app db
          await TaskEventRepository.getAllPaged(ChronologicalPaging.start(10), dbToRestoreName);
          await dbToRestore.close();

          // delete journal file
          final dbJournalFile = File(dbJournalPath);
          if (dbJournalFile.existsSync()) dbJournalFile.delete();

          // do restore if no exception happens
          final replacedDbFile = await restoreDbFile.copy(dbPath);
          debugPrint("file replaced: ${replacedDbFile.path}");
          restoreDbFile.delete();

          //reopening
          (await getDb()).close();
          await getDb();


        } catch (e, trace) {
          print(e);
          debugPrintStack(stackTrace: trace);
          debugPrint("corrupt file detected, ignore it!");
          if (restoreDbFile?.existsSync()??false) restoreDbFile?.delete();

          errorHandler("This is not an EverydayTasks backup file!");
          return;
        }
        finally {
          await dbToRestore?.close();
        }

        successHandler(true);
      } else {
        successHandler(false);
      }
    } catch (e) {
      errorHandler("Cannot import database!");
      print(e);
    }
  }


  String _getFullPath(String basePath, int? version) =>
      version != null ? "$basePath ($version).db" : "$basePath.db";
}
