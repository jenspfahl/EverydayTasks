import 'Severity.dart';

class TaskEvent implements Comparable {
  int? id;
  int? taskGroupId;

  String name;
  String? description;
  int? colorRGB;
  DateTime startedAt;
  DateTime finishedAt;
  Severity severity = Severity.MEDIUM;
  bool favorite = false;

  TaskEvent(this.id, this.taskGroupId, this.name, this.description, this.colorRGB,
      this.startedAt, this.finishedAt, this.severity, this.favorite);

    TaskEvent.newInstance(this.taskGroupId, this.name, this.description, this.colorRGB,
      this.startedAt, this.finishedAt, this.severity);

    TaskEvent.newPlainInstance(this.name, this.startedAt, this.finishedAt);

  @override
  int compareTo(other) {
    int result = other.startedAt.compareTo(startedAt);
    if (result != 0) return result;
    return other.id??0.compareTo(id??0);
  }

}