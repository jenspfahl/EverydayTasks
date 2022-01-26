import 'Severity.dart';
import 'When.dart';

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
}