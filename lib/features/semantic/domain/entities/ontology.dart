import 'ontology_class.dart';
import 'ontology_property.dart';

/// Representa uma ontologia completa (conjunto de classes e propriedades)
/// 
/// Uma ontologia define o vocabulário e as regras do domínio semântico.
/// Pode ser importada/exportada em formato OWL/RDF.
class Ontology {
  /// ID único da ontologia
  final String id;
  
  /// URI base da ontologia (namespace)
  final String baseUri;
  
  /// Nome da ontologia
  final String name;
  
  /// Descrição
  final String? description;
  
  /// Versão
  final String version;
  
  /// Classes definidas na ontologia
  final List<OntologyClass> classes;
  
  /// Propriedades definidas na ontologia
  final List<OntologyProperty> properties;
  
  /// URIs de ontologias importadas
  final List<String> imports;
  
  /// Prefixos para namespaces externos
  final Map<String, String> prefixes;
  
  /// Data de criação
  final DateTime createdAt;
  
  /// Data de última modificação
  final DateTime? updatedAt;
  
  /// Metadados adicionais
  final Map<String, dynamic> metadata;

  Ontology({
    required this.id,
    required this.baseUri,
    required this.name,
    this.description,
    this.version = '1.0.0',
    this.classes = const [],
    this.properties = const [],
    this.imports = const [],
    this.prefixes = const {},
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  /// Prefixos padrão incluindo os comuns de RDF/OWL
  Map<String, String> get allPrefixes => {
        'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        'rdfs': 'http://www.w3.org/2000/01/rdf-schema#',
        'owl': 'http://www.w3.org/2002/07/owl#',
        'xsd': 'http://www.w3.org/2001/XMLSchema#',
        'app': baseUri,
        ...prefixes,
      };

  /// Cria uma cópia com valores alterados
  Ontology copyWith({
    String? id,
    String? baseUri,
    String? name,
    String? description,
    String? version,
    List<OntologyClass>? classes,
    List<OntologyProperty>? properties,
    List<String>? imports,
    Map<String, String>? prefixes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Ontology(
      id: id ?? this.id,
      baseUri: baseUri ?? this.baseUri,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      classes: classes ?? this.classes,
      properties: properties ?? this.properties,
      imports: imports ?? this.imports,
      prefixes: prefixes ?? this.prefixes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Busca uma classe pelo URI
  OntologyClass? getClass(String uri) {
    try {
      return classes.firstWhere((c) => c.uri == uri);
    } catch (_) {
      return null;
    }
  }

  /// Busca uma classe pelo nome local
  OntologyClass? getClassByName(String localName) {
    try {
      return classes.firstWhere((c) => c.localName == localName);
    } catch (_) {
      return null;
    }
  }

  /// Busca uma propriedade pelo URI
  OntologyProperty? getProperty(String uri) {
    try {
      return properties.firstWhere((p) => p.uri == uri);
    } catch (_) {
      return null;
    }
  }

  /// Busca propriedades de uma classe (incluindo herdadas)
  List<OntologyProperty> getPropertiesForClass(String classUri) {
    final result = <OntologyProperty>[];
    final targetClass = getClass(classUri);
    
    if (targetClass == null) return result;
    
    // Propriedades diretas da classe
    result.addAll(properties.where((p) => p.domainUri == classUri));
    
    // Propriedades herdadas da classe pai
    if (targetClass.parentClassUri != null) {
      result.addAll(getPropertiesForClass(targetClass.parentClassUri!));
    }
    
    return result;
  }

  /// Retorna subclasses diretas de uma classe
  List<OntologyClass> getSubclasses(String classUri) {
    return classes.where((c) => c.parentClassUri == classUri).toList();
  }

  /// Retorna todas as subclasses (recursivo)
  List<OntologyClass> getAllSubclasses(String classUri) {
    final result = <OntologyClass>[];
    final directSubclasses = getSubclasses(classUri);
    
    for (final subclass in directSubclasses) {
      result.add(subclass);
      result.addAll(getAllSubclasses(subclass.uri));
    }
    
    return result;
  }

  /// Retorna classes raiz (sem pai)
  List<OntologyClass> get rootClasses {
    return classes.where((c) => c.parentClassUri == null).toList();
  }

  /// Gera URI completo a partir do nome local
  String makeUri(String localName) {
    return '$baseUri#$localName';
  }

  /// Gera definição OWL/RDF em XML
  String toOwlXml() {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<rdf:RDF');
    
    // Adicionar prefixos
    for (final entry in allPrefixes.entries) {
      buffer.writeln('  xmlns:${entry.key}="${entry.value}"');
    }
    buffer.writeln('  xml:base="$baseUri">');
    buffer.writeln();

    // Declaração da ontologia
    buffer.writeln('  <owl:Ontology rdf:about="$baseUri">');
    buffer.writeln('    <rdfs:label>$name</rdfs:label>');
    if (description != null) {
      buffer.writeln('    <rdfs:comment>$description</rdfs:comment>');
    }
    buffer.writeln('    <owl:versionInfo>$version</owl:versionInfo>');
    for (final importUri in imports) {
      buffer.writeln('    <owl:imports rdf:resource="$importUri"/>');
    }
    buffer.writeln('  </owl:Ontology>');
    buffer.writeln();

    // Classes
    for (final ontClass in classes) {
      buffer.writeln('  <owl:Class rdf:about="${ontClass.uri}">');
      buffer.writeln('    <rdfs:label>${ontClass.label}</rdfs:label>');
      if (ontClass.description != null) {
        buffer.writeln('    <rdfs:comment>${ontClass.description}</rdfs:comment>');
      }
      if (ontClass.parentClassUri != null) {
        buffer.writeln('    <rdfs:subClassOf rdf:resource="${ontClass.parentClassUri}"/>');
      }
      // Adicionar restrições
      for (final restriction in ontClass.restrictions) {
        buffer.writeln('    <rdfs:subClassOf>');
        buffer.writeln('      <owl:Restriction>');
        buffer.writeln('        <owl:onProperty rdf:resource="${restriction.propertyUri}"/>');
        buffer.writeln('        <owl:${_restrictionTypeToOwl(restriction.type)}>${restriction.value}</owl:${_restrictionTypeToOwl(restriction.type)}>');
        buffer.writeln('      </owl:Restriction>');
        buffer.writeln('    </rdfs:subClassOf>');
      }
      buffer.writeln('  </owl:Class>');
      buffer.writeln();
    }

    // Propriedades
    for (final prop in properties) {
      final propType = prop.isObjectProperty ? 'ObjectProperty' : 'DatatypeProperty';
      buffer.writeln('  <owl:$propType rdf:about="${prop.uri}">');
      buffer.writeln('    <rdfs:label>${prop.label}</rdfs:label>');
      if (prop.description != null) {
        buffer.writeln('    <rdfs:comment>${prop.description}</rdfs:comment>');
      }
      buffer.writeln('    <rdfs:domain rdf:resource="${prop.domainUri}"/>');
      buffer.writeln('    <rdfs:range rdf:resource="${prop.rangeUri}"/>');
      if (prop.isFunctional) {
        buffer.writeln('    <rdf:type rdf:resource="http://www.w3.org/2002/07/owl#FunctionalProperty"/>');
      }
      if (prop.inversePropertyUri != null) {
        buffer.writeln('    <owl:inverseOf rdf:resource="${prop.inversePropertyUri}"/>');
      }
      buffer.writeln('  </owl:$propType>');
      buffer.writeln();
    }

    buffer.writeln('</rdf:RDF>');

    return buffer.toString();
  }

  String _restrictionTypeToOwl(RestrictionType type) {
    switch (type) {
      case RestrictionType.maxCardinality:
        return 'maxCardinality';
      case RestrictionType.minCardinality:
        return 'minCardinality';
      case RestrictionType.exactCardinality:
        return 'cardinality';
      case RestrictionType.someValuesFrom:
        return 'someValuesFrom';
      case RestrictionType.allValuesFrom:
        return 'allValuesFrom';
      case RestrictionType.hasValue:
        return 'hasValue';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ontology &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Ontology(id: $id, name: $name, classes: ${classes.length})';
}
