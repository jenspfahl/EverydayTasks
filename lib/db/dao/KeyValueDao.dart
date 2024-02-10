import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/SequencesEntity.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';

import '../entity/KeyValueEntity.dart';

@dao
abstract class KeyValueDao {

  @Query('SELECT * FROM KeyValueEntity WHERE id = :id')
  Stream<KeyValueEntity?> findById(int id);

  @Query('SELECT * FROM KeyValueEntity WHERE `key` = :key')
  Stream<KeyValueEntity?> findByKey(String key);

  @Query('SELECT * FROM KeyValueEntity '
      'ORDER BY key, id')
  Future<List<KeyValueEntity>> findAll();

  @insert
  Future<int> insertKeyValue(KeyValueEntity entity);

  @update
  Future<int> updateKeyValue(KeyValueEntity entity);

  @delete
  Future<int> deleteKeyValue(KeyValueEntity entity);

}

