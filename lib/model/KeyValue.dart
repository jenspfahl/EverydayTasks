class KeyValue {
  int? id;
  final String key;
  String value;

  KeyValue(this.id, this.key, this.value);


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyValue && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() {
    return 'KeyValue{id: $id, key: $key, value: $value}';
  }
}