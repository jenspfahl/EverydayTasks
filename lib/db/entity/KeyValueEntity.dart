import 'package:floor/floor.dart';

@Entity(indices: [
  Index(
    name: 'idx_KeyValue_key',
    value: ['key'],
    unique: true,
  ),
])class KeyValueEntity {
  @primaryKey
  int? id;
  final String key;
  String value;


  KeyValueEntity(
      this.id,
      this.key,
      this.value,
      );
}