/// Representa uma classe OWL (ex: Aula, Pessoa, Evento)
/// 
/// Classes definem tipos de entidades no domínio semântico.
/// Podem ter hierarquia (subclasses) e propriedades associadas.
class OntologyClass {
  /// URI único da classe (ex: "http://meuapp.com/ontology#Aula")
  final String uri;
  
  /// Nome legível da classe (ex: "Aula")
  final String label;
  
  /// Descrição opcional da classe
  final String? description;
  
  /// URI da classe pai (para hierarquia)
  final String? parentClassUri;
  
  /// Lista de URIs das propriedades desta classe
  final List<String> propertyUris;
  
  /// Restrições OWL DL (ex: "maxCardinality 1 temHorario")
  final List<OntologyRestriction> restrictions;
  
  /// Metadados adicionais
  final Map<String, dynamic> metadata;

  OntologyClass({
    required this.uri,
    required this.label,
    this.description,
    this.parentClassUri,
    this.propertyUris = const [],
    this.restrictions = const [],
    this.metadata = const {},
  });

  /// Cria uma cópia com valores alterados
  OntologyClass copyWith({
    String? uri,
    String? label,
    String? description,
    String? parentClassUri,
    List<String>? propertyUris,
    List<OntologyRestriction>? restrictions,
    Map<String, dynamic>? metadata,
  }) {
    return OntologyClass(
      uri: uri ?? this.uri,
      label: label ?? this.label,
      description: description ?? this.description,
      parentClassUri: parentClassUri ?? this.parentClassUri,
      propertyUris: propertyUris ?? this.propertyUris,
      restrictions: restrictions ?? this.restrictions,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Extrai o nome local da URI (parte após # ou último /)
  String get localName {
    if (uri.contains('#')) {
      return uri.split('#').last;
    }
    return uri.split('/').last;
  }

  /// Verifica se é subclasse de outra classe
  bool isSubclassOf(String classUri) {
    return parentClassUri == classUri;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OntologyClass &&
          runtimeType == other.runtimeType &&
          uri == other.uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'OntologyClass(uri: $uri, label: $label)';
}

/// Representa uma restrição OWL DL sobre uma classe
class OntologyRestriction {
  /// Tipo da restrição
  final RestrictionType type;
  
  /// URI da propriedade afetada
  final String propertyUri;
  
  /// Valor da restrição (ex: cardinalidade, classe alvo)
  final dynamic value;
  
  /// Descrição legível da restrição
  final String? description;

  OntologyRestriction({
    required this.type,
    required this.propertyUri,
    required this.value,
    this.description,
  });

  @override
  String toString() {
    switch (type) {
      case RestrictionType.maxCardinality:
        return 'max $value $propertyUri';
      case RestrictionType.minCardinality:
        return 'min $value $propertyUri';
      case RestrictionType.exactCardinality:
        return 'exactly $value $propertyUri';
      case RestrictionType.someValuesFrom:
        return 'some $propertyUri $value';
      case RestrictionType.allValuesFrom:
        return 'only $propertyUri $value';
      case RestrictionType.hasValue:
        return 'value $propertyUri $value';
    }
  }
}

/// Tipos de restrições OWL DL suportadas
enum RestrictionType {
  /// Cardinalidade máxima (owl:maxCardinality)
  maxCardinality,
  
  /// Cardinalidade mínima (owl:minCardinality)
  minCardinality,
  
  /// Cardinalidade exata (owl:cardinality)
  exactCardinality,
  
  /// Existencial (owl:someValuesFrom)
  someValuesFrom,
  
  /// Universal (owl:allValuesFrom)
  allValuesFrom,
  
  /// Valor específico (owl:hasValue)
  hasValue,
}
