import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/TemplateId.dart';

import '../util/i18n.dart';
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
    required String i18nTitle,
    String? description,
    When? when,
    Severity? severity
  }) : super(
    tId: new TemplateId.forTaskTemplate(1000 * taskGroupId + subId),
    taskGroupId: taskGroupId,
    title: _createI18nKey(taskGroupId, i18nTitle),
    description: description,
    when: when,
    severity: severity,
  );

  static String _createI18nKey(int taskGroupId, String i18nTitle) {
    final taskGroup = findPredefinedTaskGroupById(taskGroupId);
    final taskGroupName = taskGroup.name;
    if (isI18nKey(taskGroupName)) {
      final key = extractI18nKey(taskGroupName);
      final newKey = key.substring(0,key.indexOf(".name")) + ".templates." + i18nTitle + ".title";
      return wrapToI18nKey(newKey);

    }
    else {
      return i18nTitle;
    }
  }


}


List<TaskTemplate> predefinedTaskTemplates = [

  // Cleaning and tidy up
  TaskTemplate.data(subId: -1, i18nTitle: 'tidy_up', taskGroupId: -1),
  TaskTemplate.data(subId: -2, i18nTitle: "Cleaning", taskGroupId: -1),
  TaskTemplate.data(subId: -3, i18nTitle: "Hoovering", taskGroupId: -1),
  TaskTemplate.data(subId: -4, i18nTitle: "Wiping", taskGroupId: -1),
  TaskTemplate.data(subId: -5, i18nTitle: "Empty bin", taskGroupId: -1),
  TaskTemplate.data(subId: -6, i18nTitle: "Dispose old paper and waste glass", taskGroupId: -1),

  // Laundry
  TaskTemplate.data(subId: -1, i18nTitle: "Fill washing machine", taskGroupId: -2),
  TaskTemplate.data(subId: -2, i18nTitle: "Empty washing machine", description: "Empty it and put on laundry rack", taskGroupId: -2),
  TaskTemplate.data(subId: -3, i18nTitle: "Get from laundry rack", taskGroupId: -2),
  TaskTemplate.data(subId: -4, i18nTitle: "Put to closet", taskGroupId: -2),
  TaskTemplate.data(subId: -5, i18nTitle: "Ironing", taskGroupId: -2),
  TaskTemplate.data(subId: -6, i18nTitle: "Change bed linen", taskGroupId: -2),
  TaskTemplate.data(subId: -7, i18nTitle: "Change towels", taskGroupId: -2),

  // Cooking
  TaskTemplate.data(subId: -1, i18nTitle: "Prepare breakfast", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.MORNING)),
  TaskTemplate.data(subId: -2, i18nTitle: "Cook lunch", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.NOON)),
  TaskTemplate.data(subId: -3, i18nTitle: "Prepare dinner", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.EVENING)),

  // Dishes
  TaskTemplate.data(subId: -1, i18nTitle: "Wash up", taskGroupId: -4),
  TaskTemplate.data(subId: -2, i18nTitle: "Dry up", taskGroupId: -4),
  TaskTemplate.data(subId: -3, i18nTitle: "Fill and start dishwasher", taskGroupId: -4),
  TaskTemplate.data(subId: -4, i18nTitle: "Empty dishwasher", taskGroupId: -4),

  // Errands
  TaskTemplate.data(subId: -1, i18nTitle: "Shop groceries", taskGroupId: -5),
  TaskTemplate.data(subId: -2, i18nTitle: "Shop diapers", taskGroupId: -5),

  // Kids
  TaskTemplate.data(subId: -1, i18nTitle: "Feeding", taskGroupId: -6),
  TaskTemplate.data(subId: -2, i18nTitle: "Bring to daycare", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.MORNING)),
  TaskTemplate.data(subId: -3, i18nTitle: "Pickup from daycare", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.AFTERNOON)),
  TaskTemplate.data(subId: -4, i18nTitle: "Bring to bed", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.EVENING)),

  // Indoor plants
  TaskTemplate.data(subId: -1, i18nTitle: "Water plants", taskGroupId: -7),
  TaskTemplate.data(subId: -2, i18nTitle: "Dung plants", taskGroupId: -7),

  // Garden
  TaskTemplate.data(subId: -1, i18nTitle: "Water vegetable patch", taskGroupId: -8),
  TaskTemplate.data(subId: -2, i18nTitle: "Dig vegetable patch", taskGroupId: -8),
  TaskTemplate.data(subId: -3, i18nTitle: "Cut the lawn", taskGroupId: -8),

  // Maintenance
  TaskTemplate.data(subId: -1, i18nTitle: "Defrost fridge", taskGroupId: -9),
  TaskTemplate.data(subId: -2, i18nTitle: "Fixing", taskGroupId: -9),

  // Organization
  TaskTemplate.data(subId: -1, i18nTitle: "Organize vacation", taskGroupId: -10),
  TaskTemplate.data(subId: -2, i18nTitle: "Shop gifts", taskGroupId: -10),

  // Car
  TaskTemplate.data(subId: -1, i18nTitle: "Regular inspection", taskGroupId: -11),
  TaskTemplate.data(subId: -2, i18nTitle: "Change windshield wipers", taskGroupId: -11),
  TaskTemplate.data(subId: -3, i18nTitle: "Change tires", taskGroupId: -11),

  // Pets
  TaskTemplate.data(subId: -1, i18nTitle: "Go for a walk with the dog", taskGroupId: -12),
  TaskTemplate.data(subId: -2, i18nTitle: "Clean aquarium/terrarium", taskGroupId: -12),
  TaskTemplate.data(subId: -3, i18nTitle: "Go to vet", taskGroupId: -12),

  // Finance
  TaskTemplate.data(subId: -1, i18nTitle: "Pay instalments", taskGroupId: -13),
  TaskTemplate.data(subId: -2, i18nTitle: "Pay rent", taskGroupId: -13),

  // Health
  TaskTemplate.data(subId: -1, i18nTitle: "Take medication", taskGroupId: -14),
  TaskTemplate.data(subId: -2, i18nTitle: "Regular health check up", taskGroupId: -14),
  TaskTemplate.data(subId: -3, i18nTitle: "Yearly dentist examination", taskGroupId: -14),

  // Sport
  TaskTemplate.data(subId: -1, i18nTitle: "Go to gym", taskGroupId: -15),
  TaskTemplate.data(subId: -2, i18nTitle: "Do a workout", taskGroupId: -15),

  // Work
  TaskTemplate.data(subId: -1, i18nTitle: "Submit expenses", taskGroupId: -16),
  TaskTemplate.data(subId: -2, i18nTitle: "Negotiate salary", taskGroupId: -16),



];
