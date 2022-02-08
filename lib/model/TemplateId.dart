

class TemplateId {

  int id;
  bool isVariant;

  TemplateId(this.id, this.isVariant);
  TemplateId.forTaskTemplate(this.id) : isVariant = false;
  TemplateId.forTaskTemplateVariant(this.id) : isVariant = true;

  int? get taskTemplateId => !this.isVariant ? id : null;
  int? get taskTemplateVariantId => this.isVariant ? id : null;

  @override
  String toString() {
    return 'TemplateId{id: $id, isVariant: $isVariant}';
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateId &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isVariant == other.isVariant;

  @override
  int get hashCode => id.hashCode ^ isVariant.hashCode;

}