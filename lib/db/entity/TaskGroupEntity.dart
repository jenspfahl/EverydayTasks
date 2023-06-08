import 'package:floor/floor.dart';

@entity
class TaskGroupEntity {
  @primaryKey
  final int? id;

  final String name;
  final int? colorRGB;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final bool? hidden;

  TaskGroupEntity(this.id,
      this.name, this.colorRGB, this.iconCodePoint, this.iconFontFamily, this.iconFontPackage, this.hidden);
}