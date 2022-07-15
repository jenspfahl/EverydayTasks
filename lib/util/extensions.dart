extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
extension ListExtension<E> on List<E> {
  List<E> append(E elem) {
    this.add(elem);
    return this;
  }
}