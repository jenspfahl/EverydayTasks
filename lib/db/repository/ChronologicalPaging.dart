class ChronologicalPaging {

  static DateTime minDateTime = DateTime.utc(-271821,01,01);
  static DateTime maxDateTime = DateTime.utc(275760,01,01);
  static int minId = -10000000000;
  static int maxId = 10000000000;

  final DateTime lastDateTime;
  final int lastId;
  final int size;

  ChronologicalPaging(this.lastDateTime, this.lastId, this.size);
}