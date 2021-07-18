import 'Severity.dart';

class TaskEvent implements Comparable {
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

  @override
  int compareTo(other) {
    int result = other.startedAt.compareTo(startedAt);
    if (result != 0) return result;
    return other.id??0.compareTo(id??0);
  }

}