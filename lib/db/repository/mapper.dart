
int dateTimeToEntity(DateTime dateTime) => dateTime.millisecondsSinceEpoch;

DateTime dateTimeFromEntity(int fromEntity) => DateTime.fromMillisecondsSinceEpoch(fromEntity);