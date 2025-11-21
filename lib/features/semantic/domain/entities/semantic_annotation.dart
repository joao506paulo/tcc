/// Representa uma anotação semântica de uma nota
/// 
/// Vincula uma nota a um template semântico e armazena
/// os valores das propriedades preenchidas pelo usuário.
class SemanticAnnotation {
  /// ID único da anotação
  final String id;
  
  /// ID da nota anotada
  final String noteId;
  
  /// ID do template semântico usado
  final String templateId;
  
  /// URI da classe OWL da nota
  final String classUri;
  
  /// Valores das propriedades (propertyUri -> valor)
  final Map<String, dynamic> propertyValues;
  
  /// IDs de notas relacionadas via ObjectProperties
  final List<NoteRelation> relations;
  
  /// Data de criação
  final DateTime createdAt;
  
  /// Data de última modificação
  final DateTime? updatedAt;
  
  /// Metadados adicionais
  final Map<String, dynamic> metadata;

  SemanticAnnotation({
    required this.id,
    required this.noteId,
    required this.templateId,
    required this.classUri,
    this.propertyValues = const {},
    this.relations = const [],
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  /// Cria uma cópia com valores alterados
  SemanticAnnotation copyWith({
    String? id,
    String? noteId,
    String? templateId,
    String? classUri,
    Map<String, dynamic>? propertyValues,
    List<NoteRelation>? relations,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SemanticAnnotation(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      templateId: templateId ?? this.templateId,
      classUri: classUri ?? this.classUri,
      propertyValues: propertyValues ?? this.propertyValues,
      relations: relations ?? this.relations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Gera triplas RDF a partir da anotação
  List<RdfTriple> toTriples() {
    final triples = <RdfTriple>[];
    final subjectUri = 'http://meuapp.com/notes#$noteId';

    // Tripla de tipo (rdf:type)
    triples.add(RdfTriple(
      subject: subjectUri,
      predicate: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
      object: classUri,
      isLiteral: false,
    ));

    // Triplas de propriedades
    for (final entry in propertyValues.entries) {
      triples.add(RdfTriple(
        subject: subjectUri,
        predicate: entry.key,
        object: entry.value.toString(),
        isLiteral: true,
        datatype: _inferDatatype(entry.value),
      ));
    }

    // Triplas de relacionamentos
    for (final relation in relations) {
      triples.add(RdfTriple(
        subject: subjectUri,
        predicate: relation.propertyUri,
        object: 'http://meuapp.com/notes#${relation.targetNoteId}',
        isLiteral: false,
      ));
    }

    return triples;
  }

  /// Gera RDF/XML a partir da anotação
  String toRdfXml() {
    final buffer = StringBuffer();
    final subjectUri = 'http://meuapp.com/notes#$noteId';
    final classLocalName = classUri.split('#').last;

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<rdf:RDF');
    buffer.writeln('  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"');
    buffer.writeln('  xmlns:owl="http://www.w3.org/2002/07/owl#"');
    buffer.writeln('  xmlns:app="http://meuapp.com/ontology#">');
    buffer.writeln();
    buffer.writeln('  <app:$classLocalName rdf:about="$subjectUri">');

    // Propriedades de dados
    for (final entry in propertyValues.entries) {
      final propLocalName = entry.key.split('#').last;
      final value = _escapeXml(entry.value.toString());
      buffer.writeln('    <app:$propLocalName>$value</app:$propLocalName>');
    }

    // Relacionamentos
    for (final relation in relations) {
      final propLocalName = relation.propertyUri.split('#').last;
      final targetUri = 'http://meuapp.com/notes#${relation.targetNoteId}';
      buffer.writeln('    <app:$propLocalName rdf:resource="$targetUri"/>');
    }

    buffer.writeln('  </app:$classLocalName>');
    buffer.writeln('</rdf:RDF>');

    return buffer.toString();
  }

  /// Infere o datatype XSD baseado no tipo Dart
  String? _inferDatatype(dynamic value) {
    if (value is int) {
      return 'http://www.w3.org/2001/XMLSchema#integer';
    } else if (value is double) {
      return 'http://www.w3.org/2001/XMLSchema#decimal';
    } else if (value is bool) {
      return 'http://www.w3.org/2001/XMLSchema#boolean';
    } else if (value is DateTime) {
      return 'http://www.w3.org/2001/XMLSchema#dateTime';
    }
    return 'http://www.w3.org/2001/XMLSchema#string';
  }

  /// Escapa caracteres especiais XML
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticAnnotation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SemanticAnnotation(id: $id, noteId: $noteId, templateId: $templateId)';
}

/// Representa um relacionamento entre notas via ObjectProperty
class NoteRelation {
  /// URI da propriedade que define o relacionamento
  final String propertyUri;
  
  /// ID da nota de destino
  final String targetNoteId;
  
  /// Label opcional do relacionamento
  final String? label;

  NoteRelation({
    required this.propertyUri,
    required this.targetNoteId,
    this.label,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteRelation &&
          runtimeType == other.runtimeType &&
          propertyUri == other.propertyUri &&
          targetNoteId == other.targetNoteId;

  @override
  int get hashCode => propertyUri.hashCode ^ targetNoteId.hashCode;
}

/// Representa uma tripla RDF (sujeito, predicado, objeto)
class RdfTriple {
  /// URI do sujeito
  final String subject;
  
  /// URI do predicado
  final String predicate;
  
  /// Valor do objeto (URI ou literal)
  final String object;
  
  /// Se o objeto é um literal (vs URI)
  final bool isLiteral;
  
  /// Datatype XSD (para literais)
  final String? datatype;
  
  /// Linguagem (para literais de texto)
  final String? language;

  RdfTriple({
    required this.subject,
    required this.predicate,
    required this.object,
    this.isLiteral = true,
    this.datatype,
    this.language,
  });

  /// Formato N-Triples
  String toNTriples() {
    final subjectStr = '<$subject>';
    final predicateStr = '<$predicate>';
    String objectStr;

    if (isLiteral) {
      objectStr = '"$object"';
      if (datatype != null) {
        objectStr += '^^<$datatype>';
      } else if (language != null) {
        objectStr += '@$language';
      }
    } else {
      objectStr = '<$object>';
    }

    return '$subjectStr $predicateStr $objectStr .';
  }

  @override
  String toString() => toNTriples();
}
