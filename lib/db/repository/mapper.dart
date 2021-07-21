
int dateTimeToEntity(DateTime dateTime) => dateTime.millisecondsSinceEpoch;
DateTime dateTimeFromEntity(int fromEntity) => DateTime.fromMillisecondsSinceEpoch(fromEntity);


int durationToEntity(Duration duration) => duration.inMinutes;
Duration durationFromEntity(int fromEntity) => Duration(minutes: fromEntity);