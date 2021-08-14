import 'package:personaltasklogger/model/Template.dart';

import 'Severity.dart';
import 'When.dart';

class TaskTemplateVariant extends Template {
  int taskTemplateId;

  TaskTemplateVariant({int? id, required this.taskTemplateId,
    required String title, String? description, When? when, Severity? severity, bool? favorite})
      : super(id: id, title: title, description: description, when: when, severity: severity, favorite: favorite);
}


List<TaskTemplateVariant> predefinedTaskTemplateVariants = [

  // Tidy up
  TaskTemplateVariant(id: -1001001, title: "Tidy up kitchen", taskTemplateId: -1001),
  TaskTemplateVariant(id: -1001002, title: "Tidy up living room", taskTemplateId: -1001),

  // Dishes / Wash up
  TaskTemplateVariant(id: -4001001, title: "Wash up after dinner", taskTemplateId: -4001, when: When.aroundAt(AroundWhenAtDay.EVENING)),

];

TaskTemplateVariant findTaskTemplateVariantById(int id) =>
    predefinedTaskTemplateVariants.firstWhere((element) => element.id == id);

List<TaskTemplateVariant >findTaskTemplateVariantsByTaskTemplateId(int taskTemplateId) =>
    predefinedTaskTemplateVariants.where((element) => element.taskTemplateId == taskTemplateId).toList();
