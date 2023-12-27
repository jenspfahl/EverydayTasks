import 'package:personaltasklogger/db/repository/IdPaging.dart';

class ChronologicalPaging extends IdPaging {
  static int minId = -10000000000;
  static int maxId = 10000000000;
  static DateTime minDateTime = DateTime.utc(-271821,01,01);
  static DateTime maxDateTime = DateTime.utc(275760,01,01);
  final DateTime lastDateTime;

  ChronologicalPaging(this.lastDateTime, int lastId, int size): super(lastId, size);

  ChronologicalPaging.start(int size) :
    this.lastDateTime = maxDateTime,
    super(maxId, size);

  @override
  String toString() {
    return 'ChronologicalPaging{lastDateTime: $lastDateTime, lastId: $lastId}';
  }
}