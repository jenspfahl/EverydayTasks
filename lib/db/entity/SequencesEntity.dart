import 'package:floor/floor.dart';

@entity
class SequencesEntity {
  @primaryKey
  final int? id;
  final String table;
  int lastId;


  SequencesEntity(
      this.id,
      this.table,
      this.lastId,
      );
}