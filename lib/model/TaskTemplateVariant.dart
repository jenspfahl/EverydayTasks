import 'Severity.dart';
import 'When.dart';

class TaskTemplateVariant {
  int? id;
  int taskTemplateId;

  String title;
  String? description;
  When? when;
  Severity? severity;
  bool? favorite = false;

  TaskTemplateVariant({this.id, required this.taskTemplateId,
      required this.title, this.description, this.when, this.severity, this.favorite});
}