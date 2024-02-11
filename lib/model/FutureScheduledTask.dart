import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/ScheduledTask.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/util/dates.dart';

import '../ui/utils.dart';
import 'Schedule.dart';
import 'Template.dart';
import 'TemplateId.dart';
import 'TitleAndDescription.dart';

class FutureScheduledTask extends ScheduledTask {

  FutureScheduledTask({
    required super.taskGroupId,
    required super.title,
    required super.description,
    required super.createdAt,
    required super.schedule,
    required super.active,
    required super.pausedAt,
    required super.important,
    required super.oneTimeCompletedOn,
  });

}