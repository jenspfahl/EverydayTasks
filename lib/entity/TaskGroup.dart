import 'package:floor/floor.dart';

@entity
class TaskGroup {
  @primaryKey
  final int id;

  final String name;
  final String description;
  final int? colorRGB;
  final int? taskGroupId;

  TaskGroup(this.id, this.name, this.description, this.colorRGB, this.taskGroupId);
}