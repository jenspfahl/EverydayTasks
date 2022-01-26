import 'Severity.dart';
import 'TemplateId.dart';
import 'When.dart';

abstract class Template {
  TemplateId? tId;
  int taskGroupId;

  String title;
  String? description;
  When? when;
  Severity? severity;
  bool? favorite = false;

  Template({this.tId, required this.taskGroupId,
      required this.title, this.description, this.when, this.severity, this.favorite});

}