import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/TemplateId.dart';

import 'Severity.dart';
import 'When.dart';

class TaskTemplate extends Template {

  TaskTemplate({
    int? id, 
    required int taskGroupId,
    required String title, 
    String? description, 
    When? when, 
    Severity? severity, 
    bool? favorite,
    bool? hidden,
  }) : super(
      tId: id != null ? new TemplateId.forTaskTemplate(id) : null,
      taskGroupId: taskGroupId, 
      title: title, 
      description: description, 
      when: when, 
      severity: severity, 
      favorite: favorite,
      hidden: hidden,
  );

  TaskTemplate.data({
    required int subId,
    required int taskGroupId,
    required String title,
    String? description,
    When? when,
    Severity? severity
  }) : super(
    tId: new TemplateId.forTaskTemplate(1000 * taskGroupId + subId),
    taskGroupId: taskGroupId,
    title: title,
    description: description,
    when: when,
    severity: severity,
  );


}


List<TaskTemplate> predefinedTaskTemplates = [

  // Cleaning and tidy up
  TaskTemplate.data(subId: -1, title: "Tidy up", taskGroupId: -1),
  TaskTemplate.data(subId: -2, title: "Cleaning", taskGroupId: -1),
  TaskTemplate.data(subId: -3, title: "Hoovering", taskGroupId: -1),
  TaskTemplate.data(subId: -4, title: "Wiping", taskGroupId: -1),
  TaskTemplate.data(subId: -5, title: "Empty bin", taskGroupId: -1),
  TaskTemplate.data(subId: -6, title: "Dispose old paper and waste glass", taskGroupId: -1),

  // Laundry
  TaskTemplate.data(subId: -1, title: "Full washing machine", taskGroupId: -2),
  TaskTemplate.data(subId: -2, title: "Empty washing machine & put on laundry rack", taskGroupId: -2),
  TaskTemplate.data(subId: -3, title: "Get from laundry rack", taskGroupId: -2),
  TaskTemplate.data(subId: -4, title: "Put to closet", taskGroupId: -2),
  TaskTemplate.data(subId: -5, title: "Ironing", taskGroupId: -2),
  TaskTemplate.data(subId: -6, title: "Change bed linen", taskGroupId: -2),
  TaskTemplate.data(subId: -7, title: "Change towels", taskGroupId: -2),

  // Cooking
  TaskTemplate.data(subId: -1, title: "Prepare breakfast", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.MORNING)),
  TaskTemplate.data(subId: -2, title: "Cook lunch", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.NOON)),
  TaskTemplate.data(subId: -3, title: "Prepare dinner", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.EVENING)),

  // Dishes
  TaskTemplate.data(subId: -1, title: "Wash up", taskGroupId: -4),
  TaskTemplate.data(subId: -2, title: "Dry up", taskGroupId: -4),
  TaskTemplate.data(subId: -3, title: "Fill and and start dishwasher", taskGroupId: -4),
  TaskTemplate.data(subId: -4, title: "Empty dishwasher", taskGroupId: -4),

  // Errands
  TaskTemplate.data(subId: -1, title: "Shop groceries", taskGroupId: -5),
  TaskTemplate.data(subId: -2, title: "Shop diapers", taskGroupId: -5),

  // Kids
  TaskTemplate.data(subId: -1, title: "Feeding", taskGroupId: -6),
  TaskTemplate.data(subId: -2, title: "Bring to daycare", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.MORNING)),
  TaskTemplate.data(subId: -3, title: "Pickup from daycare", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.AFTERNOON)),
  TaskTemplate.data(subId: -4, title: "Bring to bed", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.EVENING)),

  // Indoor plants
  TaskTemplate.data(subId: -1, title: "Water plants", taskGroupId: -7),
  TaskTemplate.data(subId: -2, title: "Dung plants", taskGroupId: -7),

  // Garden
  TaskTemplate.data(subId: -1, title: "Water vegetable patch", taskGroupId: -8),
  TaskTemplate.data(subId: -2, title: "Dig vegetable patch", taskGroupId: -8),

  // Maintenance
  TaskTemplate.data(subId: -1, title: "Defrost fridge", taskGroupId: -9),
  TaskTemplate.data(subId: -2, title: "Fixing", taskGroupId: -9),

  // Organization
  TaskTemplate.data(subId: -1, title: "Organize vacation", taskGroupId: -10),
  TaskTemplate.data(subId: -2, title: "Shop gifts", taskGroupId: -10),

  // Car
  TaskTemplate.data(subId: -1, title: "Regular inspection", taskGroupId: -11),
  TaskTemplate.data(subId: -3, title: "Change tires", taskGroupId: -11),
  TaskTemplate.data(subId: -2, title: "Change windshield wipers", taskGroupId: -11),

];
