import 'package:jiffy/jiffy.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/model/TaskTemplate.dart';
import 'package:personaltasklogger/util/dates.dart';

import 'Schedule.dart';
import 'TaskTemplateVariant.dart';
import 'Template.dart';
import 'TemplateId.dart';

class ScheduledTaskEvent {
  int? id;
  int taskEventId;
  int scheduledTaskId;
  DateTime createdAt;

  ScheduledTaskEvent(
      this.id,
      this.taskEventId,
      this.scheduledTaskId,
      this.createdAt,
      );
}