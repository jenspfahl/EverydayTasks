class IdPaging {

  static int minId = -10000000000;
  static int maxId = 10000000000;

  final int lastId;
  final int size;

  IdPaging(this.lastId, this.size);
}