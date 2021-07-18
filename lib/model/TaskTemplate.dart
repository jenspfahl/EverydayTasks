import 'Severity.dart';
import 'When.dart';

class TaskTemplate {
  int? id;
  int? taskGroupId;

  String name;
  String? description;
  When? when;
  Severity? severity;
  bool? favorite = false;

  TaskTemplate({this.id, this.taskGroupId,
      required this.name, this.description, this.when, this.severity, this.favorite});
}