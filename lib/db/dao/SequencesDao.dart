import 'package:floor/floor.dart';
import 'package:personaltasklogger/db/entity/SequencesEntity.dart';
import 'package:personaltasklogger/db/entity/TaskTemplateEntity.dart';

@dao
abstract class SequencesDao {

  @Query('SELECT * FROM SequencesEntity WHERE `table` = :table')
  Stream<SequencesEntity?> findByTable(String table);

  @insert
  Future<int> insertSequence(SequencesEntity sequence);

  @update
  Future<int> updateSequence(SequencesEntity sequence);

}

