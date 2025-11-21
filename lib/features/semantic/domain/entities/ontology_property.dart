/// Representa uma propriedade OWL (ObjectProperty ou DataProperty)
/// 
/// Propriedades definem relacionamentos entre classes (ObjectProperty)
/// ou entre uma classe e um valor literal (DataProperty).
class OntologyProperty {
  /// URI único da propriedade (ex: "http://meuapp.com/ontology#temProfessor")
  final String uri;
  
  /// Nome legível da propriedade (ex: "tem Professor")
  final String label;
  
  /// Descrição opcional
  final String? description;
  
  /// Tipo da propriedade (Object ou Data)
  final PropertyType type;
  
  /// URI da classe domínio (quem possui a propriedade)
  final String domainUri;
  
  /// URI do range (tipo do valor - classe ou datatype)
  final String rangeUri;
  
  /// Se a propriedade é obrigatória
  final bool isRequired;
  
  /// Se a propriedade é funcional (máximo 1 valor)
  final bool isFunctional;
  
  /// URI da propriedade inversa (se existir)
  final String? inversePropertyUri;
  
  /// Metadados adicionais
  final Map<String, dynamic> metadata;

  OntologyProperty({
    required this.uri,
    required this.label,
    this.description,
    required this.type,
    required this.domainUri,
    required this.rangeUri,
    this.isRequired = false,
    this.isFunctional = false,
    this.inversePropertyUri,
    this.metadata = const {},
  });

  /// Cria uma cópia com valores alterados
  OntologyProperty copyWith({
    String? uri,
    String? label,
    String? description,
    PropertyType? type,
    String? domainUri,
    String? rangeUri,
    bool? isRequired,
    bool? isFunctional,
    String? inversePropertyUri,
    Map<String, dynamic>? metadata,
  }) {
    return OntologyProperty(
      uri: uri ?? this.uri,
      label: label ?? this.label,
      description: description ?? this.description,
      type: type ?? this.type,
      domainUri: domainUri ?? this.domainUri,
      rangeUri: rangeUri ?? this.rangeUri,
      isRequired: isRequired ?? this.isRequired,
      isFunctional: isFunctional ?? this.isFunctional,
      inversePropertyUri: inversePropertyUri ?? this.inversePropertyUri,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Extrai o nome local da URI
  String get localName {
    if (uri.contains('#')) {
      return uri.split('#').last;
    }
    return uri.split('/').last;
  }

  /// Verifica se é uma ObjectProperty
  bool get isObjectProperty => type == PropertyType.objectProperty;

  /// Verifica se é uma DataProperty
  bool get isDataProperty => type == PropertyType.dataProperty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OntologyProperty &&
          runtimeType == other.runtimeType &&
          uri == other.uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'OntologyProperty(uri: $uri, label: $label, type: $type)';
}

/// Tipo de propriedade OWL
enum PropertyType {
  /// Relaciona duas instâncias de classes
  objectProperty,
  
  /// Relaciona uma instância a um valor literal
  dataProperty,
}

/// Datatypes XSD comuns para DataProperties
class XsdDatatype {
  static const String string = 'http://www.w3.org/2001/XMLSchema#string';
  static const String integer = 'http://www.w3.org/2001/XMLSchema#integer';
  static const String decimal = 'http://www.w3.org/2001/XMLSchema#decimal';
  static const String boolean = 'http://www.w3.org/2001/XMLSchema#boolean';
  static const String date = 'http://www.w3.org/2001/XMLSchema#date';
  static const String dateTime = 'http://www.w3.org/2001/XMLSchema#dateTime';
  static const String time = 'http://www.w3.org/2001/XMLSchema#time';
  static const String anyUri = 'http://www.w3.org/2001/XMLSchema#anyURI';
  
  /// Retorna o nome legível do datatype
  static String getLabel(String uri) {
    switch (uri) {
      case string:
        return 'Texto';
      case integer:
        return 'Número Inteiro';
      case decimal:
        return 'Número Decimal';
      case boolean:
        return 'Verdadeiro/Falso';
      case date:
        return 'Data';
      case dateTime:
        return 'Data e Hora';
      case time:
        return 'Hora';
      case anyUri:
        return 'URL';
      default:
        return uri.split('#').last;
    }
  }
  
  /// Lista de todos os datatypes suportados
  static List<String> get all => [
    string,
    integer,
    decimal,
    boolean,
    date,
    dateTime,
    time,
    anyUri,
  ];
}
