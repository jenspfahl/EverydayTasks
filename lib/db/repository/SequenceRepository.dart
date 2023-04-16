import 'package:flutter/cupertino.dart';
import 'package:personaltasklogger/db/entity/SequencesEntity.dart';

import '../database.dart';

class SequenceRepository {

  static Future<int> nextSequenceId(AppDatabase database, String entityName) async {
    final sequencesDao = await database.sequencesDao;
    var sequencesEntity = await sequencesDao.findByTable(entityName).first;
    if (sequencesEntity == null) {
      debugPrint("Sequence for $entityName not initialized, do it now");
      sequencesEntity = SequencesEntity(null, entityName, 1000);
      final sequencesEntityId = await sequencesDao.insertSequence(sequencesEntity);
      sequencesEntity.id = sequencesEntityId;
    }
    sequencesEntity.lastId = sequencesEntity.lastId + 1;
    sequencesDao.updateSequence(sequencesEntity);

    return sequencesEntity.lastId;
  }

}

