import 'package:personaltasklogger/model/Template.dart';

import 'Severity.dart';
import 'When.dart';

class TaskTemplate extends Template {
  int? taskGroupId;

  TaskTemplate({int? id, this.taskGroupId,
      required String title, String? description, When? when, Severity? severity, bool? favorite})
      : super(id: id, title: title, description: description, when: when, severity: severity, favorite: favorite);
}


List<TaskTemplate> predefinedTaskTemplates = [

  // Cleaning and tidy up
  TaskTemplate(id: -1001, title: "Tidy up", taskGroupId: -1),
  TaskTemplate(id: -1002, title: "Cleaning", taskGroupId: -1),
  TaskTemplate(id: -1003, title: "Hoovering", taskGroupId: -1),
  TaskTemplate(id: -1004, title: "Wiping", taskGroupId: -1),
  TaskTemplate(id: -1005, title: "Empty bin", taskGroupId: -1),
  TaskTemplate(id: -1006, title: "Dispose old paper and waste glass", taskGroupId: -1),
  TaskTemplate(id: -1007, title: "Clean windows", taskGroupId: -1),
  TaskTemplate(id: -1007, title: "Clean fridge", taskGroupId: -1),

  // Laundry
  TaskTemplate(id: -2001, title: "Prepare washing machine", taskGroupId: -2),
  TaskTemplate(id: -2002, title: "Empty washing machine", taskGroupId: -2),
  TaskTemplate(id: -2003, title: "Put on laundry rack", taskGroupId: -2),
  TaskTemplate(id: -2004, title: "Get from laundry rack to closet", taskGroupId: -2),
  TaskTemplate(id: -2005, title: "Ironing", taskGroupId: -2),
  TaskTemplate(id: -2006, title: "Change bed linen", taskGroupId: -2),
  TaskTemplate(id: -2007, title: "Change towels", taskGroupId: -2),

  // Cooking
  TaskTemplate(id: -3001, title: "Prepare breakfast", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.MORNING)),
  TaskTemplate(id: -3002, title: "Cook lunch", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.NOON)),
  TaskTemplate(id: -3003, title: "Prepare dinner", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.EVENING)),

  // Dishes
  TaskTemplate(id: -4001, title: "Wash up", taskGroupId: -4),
  TaskTemplate(id: -4002, title: "Dry up", taskGroupId: -4),
  TaskTemplate(id: -4003, title: "Fill and and start dishwasher", taskGroupId: -4),
  TaskTemplate(id: -4004, title: "Empty dishwasher", taskGroupId: -4),

  // Errands
  TaskTemplate(id: -5001, title: "Shop groceries", taskGroupId: -5),
  TaskTemplate(id: -5002, title: "Shop diapers", taskGroupId: -5),

  // Kids
  TaskTemplate(id: -6001, title: "Feeding", taskGroupId: -6),
  TaskTemplate(id: -6002, title: "Bring to daycare", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.FORENOON)),
  TaskTemplate(id: -6003, title: "Pickup from daycare", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.AFTERNOON)),
  TaskTemplate(id: -6004, title: "Bring to bed", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.EVENING)),

  // Maintenance
  TaskTemplate(id: -7001, title: "Defrost fridge", taskGroupId: -7),
  TaskTemplate(id: -7002, title: "Fixing", taskGroupId: -7),

  // Organization
  TaskTemplate(id: -8001, title: "Organize vacation", taskGroupId: -8),
  TaskTemplate(id: -8002, title: "Shop gifts", taskGroupId: -8),

];

TaskTemplate findTaskTemplateById(int id) => predefinedTaskTemplates.firstWhere((element) => element.id == id);

List<TaskTemplate >findTaskTemplatesByTaskGroupId(int taskGroupId) =>
    predefinedTaskTemplates.where((element) => element.taskGroupId == taskGroupId).toList();
