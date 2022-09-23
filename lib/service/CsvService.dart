import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskEventRepository.dart';
import 'package:personaltasklogger/db/repository/ScheduledTaskRepository.dart';
import 'package:personaltasklogger/db/repository/TemplateRepository.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../db/repository/ChronologicalPaging.dart';
import '../db/repository/TaskEventRepository.dart';

class CsvService {
  static final CsvService _service = CsvService._internal();

  factory CsvService() {
    return _service;
  }

  CsvService._internal();

  Future<void> backup(BuildContext context, Function(bool, String?) successHandler, Function(String) errorHandler) async {
    try {

      final destPath = await FilePicker.platform.getDirectoryPath();
      if (destPath != null) {
            final saveTo = Directory(destPath);
            if ((await saveTo.exists())) {
              final status = await Permission.storage.status;
              if (!status.isGranted) {
                await Permission.storage.request();
              }
            } else {
              if (await Permission.storage.request().isGranted) {
                // Either the permission was already granted before or the user just granted it.
                await saveTo.create();
              } else {
                errorHandler('Please give permission');
              }
            }

            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final basePath = "${saveTo.path}/EverydayTasks-Journal_$today";

            int? version;
            while(await File(_getFullPath(basePath, version)).exists()) {
              if (version == null) {
                version = 1;
              }
              else {
                version++;
              }
              if (version > 100000) {
                errorHandler('Cannot create backup file!');
                return;
              }
            }

            final csvAsString = await _getAllEventsAsCsv(context);

            final dstFile = File(_getFullPath(basePath, version));
            dstFile.writeAsString(csvAsString);
            successHandler(true, dstFile.path);
          } else {
            successHandler(false, null);
          }
    } catch (e) {
      errorHandler("Cannot export database!");
      print(e);
    }

  }

  Future<String> _getAllEventsAsCsv(BuildContext context) async {
    final paging = ChronologicalPaging(ChronologicalPaging.maxDateTime, ChronologicalPaging.maxId, 1000000);
    final taskEvents = await TaskEventRepository.getAllPaged(paging);
    final header = [
      "id",
      "title",
      "description",
      "category",
      "created_at",
      "started_at",
      "finished_at",
      "severity",
      "favorite",
      "from_task",
      "from_schedule",
    ];
    
    final csvList = [header];
    
    for (final taskEvent in taskEvents) {
      final taskGroupId = taskEvent.taskGroupId;
    
      final templateId = taskEvent.originTemplateId;
      var taskTitle = "";
      if (templateId != null) {
        final template = await TemplateRepository.findById(templateId);
        taskTitle = template?.translatedTitle??"";
      }
    
      final scheduledTaskEvent = await ScheduledTaskEventRepository.findByTaskEventId(taskEvent.id!);
      var scheduleTitle = "";
      if (scheduledTaskEvent != null) {
        final scheduledTask = await ScheduledTaskRepository.findById(scheduledTaskEvent.scheduledTaskId);
        scheduleTitle = scheduledTask?.translatedTitle??"";
      }
    
      final csv = [
        taskEvent.id?.toString()??"",
        taskEvent.translatedTitle,
        taskEvent.translatedDescription??"",
        taskGroupId != null ? findPredefinedTaskGroupById(taskGroupId).translatedName : "",
        formatToDateTime(taskEvent.createdAt, context),
        formatToDateTime(taskEvent.startedAt, context),
        formatToDateTime(taskEvent.finishedAt, context),
        severityToString(taskEvent.severity),
        taskEvent.favorite ? "x" : "",
        taskTitle,
        scheduleTitle,
      ];
      csvList.add(csv);
    }
    
    final csvAsString = const ListToCsvConverter().convert(csvList);
    return csvAsString;
  }


  String _getFullPath(String basePath, int? version) =>
      version != null ? "$basePath ($version).csv" : "$basePath.csv";
}
