import 'Severity.dart';
import 'When.dart';

abstract class Template {
  int? id;
  int taskGroupId;

  String title;
  String? description;
  When? when;
  Severity? severity;
  bool? favorite = false;

  Template({this.id, required this.taskGroupId,
      required this.title, this.description, this.when, this.severity, this.favorite});
}