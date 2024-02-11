import 'package:personaltasklogger/db/entity/KeyValueEntity.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/KeyValue.dart';
import 'package:personaltasklogger/model/TemplateId.dart';
import 'package:personaltasklogger/model/When.dart';

import '../database.dart';
import 'ChronologicalPaging.dart';
import 'TemplateRepository.dart';
import 'mapper.dart';

class KeyValueRepository {

  static Future<KeyValue> save(String key, String value) async {
    final existing = await KeyValueRepository.findByKey(key);

    if (existing != null) {
      existing.value = value;
      return KeyValueRepository.update(existing);
    }
    else {
      final newKeyValue = KeyValue(null, key, value);
      return KeyValueRepository.insert(newKeyValue);
    }

  }

  static Future<KeyValue> insert(KeyValue keyValue) async {
    final database = await getDb();

    final keyValueDao = database.keyValueDao;
    final entity = _mapToEntity(keyValue);

    final id = await keyValueDao.insertKeyValue(entity);
    keyValue.id = id;

    return keyValue;

  }

  static Future<KeyValue> update(KeyValue keyValue) async {
    final database = await getDb();

    final keyValueDao = database.keyValueDao;
    final entity = _mapToEntity(keyValue);

    await keyValueDao.updateKeyValue(entity);
    return keyValue;

  }

  static Future<int> delete(String key) async {
    final database = await getDb();

    final keyValueDao = database.keyValueDao;

    final existing = await KeyValueRepository.findByKey(key);

    if (existing != null) {
      return keyValueDao.deleteKeyValue(_mapToEntity(existing));
    }
    else {
      return 0;
    }
  }

  static Future<List<KeyValue>> findAll([String? dbName]) async {
    final database = await getDb(dbName);

    final keyValueDao = database.keyValueDao;
    return keyValueDao.findAll()
        .then((entities) => _mapFromEntities(entities));
  }

  static Future<KeyValue> getById(int id) async {
    final database = await getDb();

    final keyValueDao = database.keyValueDao;
    return await keyValueDao.findById(id)
        .map((e) => _mapFromEntity(e!))
        .first;
  }

  static Future<KeyValue?> findByKey(String key) async {
    final database = await getDb();

    final keyValueDao = database.keyValueDao;
    final keyValue = await keyValueDao.findByKey(key)
        .map((e) => e != null ? _mapFromEntity(e) : null)
        .first;

    if (keyValue == null) {
      return null;
    }
    return keyValue;
  }

  static KeyValueEntity _mapToEntity(KeyValue keyValue) =>
    KeyValueEntity(
        keyValue.id,
        keyValue.key,
        keyValue.value,
     );

  static KeyValue _mapFromEntity(KeyValueEntity entity) => KeyValue(
        entity.id,
        entity.key,
        entity.value,
        );

  static List<KeyValue> _mapFromEntities(List<KeyValueEntity> entities) =>
      entities.map(_mapFromEntity).toList();

}
