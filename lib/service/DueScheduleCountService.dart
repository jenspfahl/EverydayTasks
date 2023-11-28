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
import 'package:personaltasklogger/model/When.dart';
import 'package:personaltasklogger/service/PreferenceService.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../db/repository/ChronologicalPaging.dart';
import '../db/repository/TaskEventRepository.dart';
import '../db/repository/TaskGroupRepository.dart';
import '../util/units.dart';

class DueScheduleCountService {
  static final DueScheduleCountService _service = DueScheduleCountService._internal();

  final _dueTaskScheduleCount = ValueNotifier(0);


  factory DueScheduleCountService() {
    return _service;
  }

  DueScheduleCountService._internal();

  get count => _dueTaskScheduleCount;

  gather() {
    ScheduledTaskRepository.countDue().then((count) => _dueTaskScheduleCount.value = count??0);
  }

  inc() {
    _dueTaskScheduleCount.value++;
  }

  dec() {
    if (_dueTaskScheduleCount.value > 0) {
      _dueTaskScheduleCount.value--;
    }
  }

  bool shouldShowIndicatorValue() {
    return _dueTaskScheduleCount.value > 0 && PreferenceService().showBadgeForDueSchedules;
  }

}
