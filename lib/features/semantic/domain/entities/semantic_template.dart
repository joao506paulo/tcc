import 'ontology_class.dart';
import 'ontology_property.dart';

/// Representa um template semântico que o usuário pode usar para criar notas
/// 
/// Um template agrupa uma classe principal com suas propriedades,
/// valores padrão e a definição OWL completa.
class SemanticTemplate {
  /// ID único do template
  final String id;
  
  /// Nome do template (ex: "Aula", "Reunião", "Projeto")
  final String name;
  
  /// Descrição do template
  final String? description;
  
  /// Classe OWL principal do template
  final OntologyClass mainClass;
  
  /// Propriedades disponíveis no template
  final List<OntologyProperty> properties;
  
  /// Valores padrão para as propriedades
  final Map<String, dynamic> defaultValues;
  
  /// Definição OWL/RDF em formato XML
  final String? owlDefinition;
  
  /// Ícone do template (nome do ícone Material)
  final String? iconName;
  
  /// Cor do template (hex)
  final String? colorHex;
  
  /// Se o template está ativo
  final bool isActive;
  
  /// Data de criação
  final DateTime createdAt;
  
  /// Data de última modificação
  final DateTime? updatedAt;
  
  /// Metadados adicionais
  final Map<String, dynamic> metadata;

  SemanticTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.mainClass,
    this.properties = const [],
    this.defaultValues = const {},
    this.owlDefinition,
    this.iconName,
    this.colorHex,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  /// Cria uma cópia com valores alterados
  SemanticTemplate copyWith({
    String? id,
    String? name,
    String? description,
    OntologyClass? mainClass,
    List<OntologyProperty>? properties,
    Map<String, dynamic>? defaultValues,
    String? owlDefinition,
    String? iconName,
    String? colorHex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SemanticTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mainClass: mainClass ?? this.mainClass,
      properties: properties ?? this.properties,
      defaultValues: defaultValues ?? this.defaultValues,
      owlDefinition: owlDefinition ?? this.owlDefinition,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Retorna as propriedades obrigatórias
  List<OntologyProperty> get requiredProperties =>
      properties.where((p) => p.isRequired).toList();

  /// Retorna as propriedades opcionais
  List<OntologyProperty> get optionalProperties =>
      properties.where((p) => !p.isRequired).toList();

  /// Retorna as ObjectProperties (relacionamentos com outras entidades)
  List<OntologyProperty> get objectProperties =>
      properties.where((p) => p.isObjectProperty).toList();

  /// Retorna as DataProperties (valores literais)
  List<OntologyProperty> get dataProperties =>
      properties.where((p) => p.isDataProperty).toList();

  /// Verifica se todas as propriedades obrigatórias têm valor padrão
  bool get hasAllRequiredDefaults {
    for (final prop in requiredProperties) {
      if (!defaultValues.containsKey(prop.uri)) {
        return false;
      }
    }
    return true;
  }

  /// Valida se um mapa de valores satisfaz as propriedades obrigatórias
  ValidationResult validateValues(Map<String, dynamic> values) {
    final errors = <String>[];
    final warnings = <String>[];

    for (final prop in requiredProperties) {
      if (!values.containsKey(prop.uri) || values[prop.uri] == null) {
        errors.add('Propriedade obrigatória "${prop.label}" não preenchida');
      }
    }

    // Verificar restrições da classe principal
    for (final restriction in mainClass.restrictions) {
      // Implementar validação de restrições
      // Por enquanto, apenas registra warning
      warnings.add('Restrição não validada: $restriction');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SemanticTemplate(id: $id, name: $name)';
}

/// Resultado de validação de um template
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  @override
  String toString() {
    if (isValid) {
      return 'ValidationResult: Valid';
    }
    return 'ValidationResult: Invalid - ${errors.join(", ")}';
  }
}
