import 'package:floor/floor.dart';
import 'package:personaltasklogger/entity/Severity.dart';

@entity
class TaskEvent {
  @primaryKey
  final int id;

  final String name;
  final String description;
  final String originTaskGroup;
  final int? colorRGB;
  final DateTime startedAt;
  final DateTime finishedAt;
  final Severity severity;
  bool favorite;

  TaskEvent(this.id, this.name, this.description, this.originTaskGroup, this.colorRGB,
      this.startedAt, this.finishedAt, this.severity, this.favorite);
}