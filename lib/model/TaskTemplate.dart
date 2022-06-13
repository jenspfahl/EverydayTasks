import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/model/Template.dart';
import 'package:personaltasklogger/model/TemplateId.dart';

import '../util/i18n.dart';
import 'Severity.dart';
import 'TitleAndDescription.dart';
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
    String? i18nDescription,
    When? when,
    Severity? severity
  }) : super(
    tId: new TemplateId.forTaskTemplate(1000 * taskGroupId + subId),
    taskGroupId: taskGroupId,
    title: _createI18nKeyForTitle(taskGroupId, i18nTitle),
    description: _createI18nKeyForDescription(taskGroupId, i18nDescription),
    when: when,
    severity: severity,
  );

  static String _createI18nKeyForTitle(int taskGroupId, String i18nTitle) {
    return _createI18nKey(taskGroupId, i18nTitle, "title")!;
  }

  static String? _createI18nKeyForDescription(int taskGroupId, String? i18nDescription) {
    return _createI18nKey(taskGroupId, i18nDescription, "description");
  }
  
  static String? _createI18nKey(int taskGroupId, String? i18nKey, String subKey) {
    final taskGroup = findPredefinedTaskGroupById(taskGroupId);
    final taskGroupName = taskGroup.name;
    return TitleAndDescription.createPredefinedI18nKey(taskGroupName, i18nKey, "name", "templates", subKey);
  }


}


List<TaskTemplate> predefinedTaskTemplates = [

  // Cleaning and tidy up
  TaskTemplate.data(subId: -1, i18nTitle: 'tidy_up', taskGroupId: -1),
  TaskTemplate.data(subId: -2, i18nTitle: "cleaning", taskGroupId: -1),
  TaskTemplate.data(subId: -3, i18nTitle: "hoovering", taskGroupId: -1),
  TaskTemplate.data(subId: -4, i18nTitle: "wiping", taskGroupId: -1),
  TaskTemplate.data(subId: -5, i18nTitle: "empty_bin", taskGroupId: -1),
  TaskTemplate.data(subId: -6, i18nTitle: "dispose_wastepaper_n_used_glass", taskGroupId: -1),

  // Laundry
  TaskTemplate.data(subId: -1, i18nTitle: "fill_washing_machine", taskGroupId: -2),
  TaskTemplate.data(subId: -2, i18nTitle: "empty_washing_machine", i18nDescription: "empty_washing_machine", taskGroupId: -2),
  TaskTemplate.data(subId: -3, i18nTitle: "get_from_laundry_rack", taskGroupId: -2),
  TaskTemplate.data(subId: -4, i18nTitle: "put_to_closet", taskGroupId: -2),
  TaskTemplate.data(subId: -5, i18nTitle: "ironing", taskGroupId: -2),
  TaskTemplate.data(subId: -6, i18nTitle: "change_bed_linen", taskGroupId: -2),
  TaskTemplate.data(subId: -7, i18nTitle: "change_towels", taskGroupId: -2),

  // Cooking
  TaskTemplate.data(subId: -1, i18nTitle: "prepare_breakfast", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.MORNING)),
  TaskTemplate.data(subId: -2, i18nTitle: "cook_lunch", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.NOON)),
  TaskTemplate.data(subId: -3, i18nTitle: "prepare_dinner", taskGroupId: -3, when: When.aroundAt(AroundWhenAtDay.EVENING)),

  // Dishes
  TaskTemplate.data(subId: -1, i18nTitle: "wash_up", taskGroupId: -4),
  TaskTemplate.data(subId: -2, i18nTitle: "dry_up", taskGroupId: -4),
  TaskTemplate.data(subId: -3, i18nTitle: "fill_n_start_dishwasher", taskGroupId: -4),
  TaskTemplate.data(subId: -4, i18nTitle: "empty_dishwasher", taskGroupId: -4),

  // Errands
  TaskTemplate.data(subId: -1, i18nTitle: "shop_groceries", taskGroupId: -5),
  TaskTemplate.data(subId: -2, i18nTitle: "shop_diapers", taskGroupId: -5),

  // Kids
  TaskTemplate.data(subId: -1, i18nTitle: "feeding", taskGroupId: -6),
  TaskTemplate.data(subId: -2, i18nTitle: "bring_to_daycare", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.MORNING)),
  TaskTemplate.data(subId: -3, i18nTitle: "pickup_from_daycare", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.AFTERNOON)),
  TaskTemplate.data(subId: -4, i18nTitle: "bring_to_bed", taskGroupId: -6, when: When.aroundAt(AroundWhenAtDay.EVENING)),

  // Indoor plants
  TaskTemplate.data(subId: -1, i18nTitle: "water_plants", taskGroupId: -7),
  TaskTemplate.data(subId: -2, i18nTitle: "dung_plants", taskGroupId: -7),

  // Garden
  TaskTemplate.data(subId: -1, i18nTitle: "water_vegetable_patch", taskGroupId: -8),
  TaskTemplate.data(subId: -2, i18nTitle: "dig_vegetable_patch", taskGroupId: -8),
  TaskTemplate.data(subId: -3, i18nTitle: "cut_lawn", taskGroupId: -8),

  // Maintenance
  TaskTemplate.data(subId: -1, i18nTitle: "defrost_fridge", taskGroupId: -9),
  TaskTemplate.data(subId: -2, i18nTitle: "fixing", taskGroupId: -9),

  // Organization
  TaskTemplate.data(subId: -1, i18nTitle: "organize_vacation", taskGroupId: -10),
  TaskTemplate.data(subId: -2, i18nTitle: "shop_gifts", taskGroupId: -10),

  // Car
  TaskTemplate.data(subId: -1, i18nTitle: "regular_inspection", taskGroupId: -11),
  TaskTemplate.data(subId: -2, i18nTitle: "change_windshield_wipers", taskGroupId: -11),
  TaskTemplate.data(subId: -3, i18nTitle: "change_tires", i18nDescription: "change_tires", taskGroupId: -11),

  // Pets
  TaskTemplate.data(subId: -1, i18nTitle: "go_for_a_walk", i18nDescription: "go_for_a_walk", taskGroupId: -12),
  TaskTemplate.data(subId: -2, i18nTitle: "clean_aquarium_terrarium", taskGroupId: -12),
  TaskTemplate.data(subId: -3, i18nTitle: "go_to_vet", taskGroupId: -12),

  // Finance
  TaskTemplate.data(subId: -1, i18nTitle: "pay_instalments", taskGroupId: -13),
  TaskTemplate.data(subId: -2, i18nTitle: "pay_rent", taskGroupId: -13),

  // Health
  TaskTemplate.data(subId: -1, i18nTitle: "take_medication", taskGroupId: -14),
  TaskTemplate.data(subId: -2, i18nTitle: "regular_health_check_up", taskGroupId: -14),
  TaskTemplate.data(subId: -3, i18nTitle: "yearly_dentist_examination", taskGroupId: -14),

  // Sport
  TaskTemplate.data(subId: -1, i18nTitle: "go_to_gym", taskGroupId: -15),
  TaskTemplate.data(subId: -2, i18nTitle: "do_a_workout", taskGroupId: -15),

  // Work
  TaskTemplate.data(subId: -1, i18nTitle: "submit_expenses", taskGroupId: -16),
  TaskTemplate.data(subId: -2, i18nTitle: "negotiate_salary", taskGroupId: -16),



];
