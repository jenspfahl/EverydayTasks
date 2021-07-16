import 'package:floor/floor.dart';

@entity
class TaskGroup {
  @primaryKey
  final int id;
  final int? taskGroupId;

  final String name;
  final String description;
  final int? colorRGB;

  TaskGroup(this.id, this.taskGroupId,
      this.name, this.description, this.colorRGB);
}