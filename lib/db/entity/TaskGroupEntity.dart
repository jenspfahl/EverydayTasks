import 'package:floor/floor.dart';

@entity
class TaskGroupEntity {
  @primaryKey
  final int id;

  final String name;
  final String description;
  final int? colorRGB;

  TaskGroupEntity(this.id,
      this.name, this.description, this.colorRGB);
}