import 'Severity.dart';
import 'When.dart';

class TaskTemplateVariant {
  int? id;
  int taskTemplateId;

  String name;
  String? description;
  When? when;
  Severity? severity;
  bool? favorite = false;

  TaskTemplateVariant({this.id, required this.taskTemplateId,
      required this.name, this.description, this.when, this.severity, this.favorite});
}