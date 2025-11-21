import '../../../../core/usecases/usecase.dart';
import '../entities/ontology.dart';
import '../entities/semantic_template.dart';
import '../repositories/semantic_repository.dart';

/// Parâmetros para criar um template semântico
class CreateSemanticTemplateParams {
  final String ontologyId;
  final String classUri;
  final String name;
  final String? description;
  final Map<String, dynamic> defaultValues;
  final String? iconName;
  final String? colorHex;

  CreateSemanticTemplateParams({
    required this.ontologyId,
    required this.classUri,
    required this.name,
    this.description,
    this.defaultValues = const {},
    this.iconName,
    this.colorHex,
  });
}

/// Caso de uso para criar um template semântico a partir de uma classe
class CreateSemanticTemplate implements UseCase<SemanticTemplate, CreateSemanticTemplateParams> {
  final SemanticRepository repository;

  CreateSemanticTemplate(this.repository);

  @override
  Future<SemanticTemplate> call(CreateSemanticTemplateParams params) async {
    // Buscar ontologia
    final ontology = await repository.getOntology(params.ontologyId);
    
    if (ontology == null) {
      throw Exception('Ontologia não encontrada: ${params.ontologyId}');
    }

    // Buscar classe principal
    final mainClass = ontology.getClass(params.classUri);
    
    if (mainClass == null) {
      throw Exception('Classe não encontrada: ${params.classUri}');
    }

    // Buscar propriedades da classe (incluindo herdadas)
    final properties = await repository.getPropertiesForClass(
      params.ontologyId,
      params.classUri,
    );

    // Gerar definição OWL para o template
    final owlDefinition = _generateOwlDefinition(ontology, mainClass, properties);

    // Criar template
    final template = SemanticTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: params.name,
      description: params.description,
      mainClass: mainClass,
      properties: properties,
      defaultValues: params.defaultValues,
      owlDefinition: owlDefinition,
      iconName: params.iconName ?? _inferIconName(mainClass.label),
      colorHex: params.colorHex ?? _inferColor(mainClass.label),
      createdAt: DateTime.now(),
    );

    // Salvar template
    final success = await repository.saveTemplate(template);
    
    if (!success) {
      throw Exception('Falha ao salvar template');
    }

    return template;
  }

  /// Gera definição OWL simplificada para o template
  String _generateOwlDefinition(
    Ontology ontology,
    dynamic mainClass,
    List properties,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<rdf:RDF');
    buffer.writeln('  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"');
    buffer.writeln('  xmlns:owl="http://www.w3.org/2002/07/owl#"');
    buffer.writeln('  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"');
    buffer.writeln('  xmlns:app="${ontology.baseUri}">');
    buffer.writeln();
    
    // Classe principal
    buffer.writeln('  <owl:Class rdf:about="${mainClass.uri}">');
    buffer.writeln('    <rdfs:label>${mainClass.label}</rdfs:label>');
    if (mainClass.parentClassUri != null) {
      buffer.writeln('    <rdfs:subClassOf rdf:resource="${mainClass.parentClassUri}"/>');
    }
    buffer.writeln('  </owl:Class>');
    buffer.writeln();
    
    // Propriedades
    for (final prop in properties) {
      final propType = prop.isObjectProperty ? 'ObjectProperty' : 'DatatypeProperty';
      buffer.writeln('  <owl:$propType rdf:about="${prop.uri}">');
      buffer.writeln('    <rdfs:label>${prop.label}</rdfs:label>');
      buffer.writeln('    <rdfs:domain rdf:resource="${prop.domainUri}"/>');
      buffer.writeln('    <rdfs:range rdf:resource="${prop.rangeUri}"/>');
      buffer.writeln('  </owl:$propType>');
      buffer.writeln();
    }
    
    buffer.writeln('</rdf:RDF>');
    
    return buffer.toString();
  }

  /// Infere ícone baseado no nome da classe
  String _inferIconName(String label) {
    final lower = label.toLowerCase();
    
    if (lower.contains('aula') || lower.contains('class')) {
      return 'school';
    } else if (lower.contains('reunião') || lower.contains('meeting')) {
      return 'people';
    } else if (lower.contains('projeto') || lower.contains('project')) {
      return 'folder';
    } else if (lower.contains('pessoa') || lower.contains('person')) {
      return 'person';
    } else if (lower.contains('evento') || lower.contains('event')) {
      return 'event';
    } else if (lower.contains('local') || lower.contains('place')) {
      return 'place';
    } else if (lower.contains('tarefa') || lower.contains('task')) {
      return 'task';
    }
    
    return 'article';
  }

  /// Infere cor baseado no nome da classe
  String _inferColor(String label) {
    final lower = label.toLowerCase();
    
    if (lower.contains('aula') || lower.contains('class')) {
      return '#2196F3'; // Azul
    } else if (lower.contains('reunião') || lower.contains('meeting')) {
      return '#4CAF50'; // Verde
    } else if (lower.contains('projeto') || lower.contains('project')) {
      return '#FF9800'; // Laranja
    } else if (lower.contains('pessoa') || lower.contains('person')) {
      return '#9C27B0'; // Roxo
    } else if (lower.contains('evento') || lower.contains('event')) {
      return '#E91E63'; // Rosa
    }
    
    return '#607D8B'; // Cinza azulado
  }
}
