import 'Severity.dart';

class TaskEvent {
  int? id;
  String name;
  String? description;
  String? originTaskGroup;
  int? colorRGB;
  DateTime startedAt;
  DateTime finishedAt;
  Severity severity = Severity.MEDIUM;
  bool favorite = false;

  TaskEvent(this.id, this.name, this.description, this.originTaskGroup, this.colorRGB,
      this.startedAt, this.finishedAt, this.severity, this.favorite);

    TaskEvent.newInstance(this.name, this.description, this.originTaskGroup, this.colorRGB,
      this.startedAt, this.finishedAt, this.severity);

    TaskEvent.newPlainInstance(this.name, this.startedAt, this.finishedAt);

}