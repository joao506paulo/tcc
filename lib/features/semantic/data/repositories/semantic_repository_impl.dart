import '../../domain/entities/ontology.dart';
import '../../domain/entities/ontology_class.dart';
import '../../domain/entities/ontology_property.dart';
import '../../domain/entities/semantic_template.dart';
import '../../domain/entities/semantic_annotation.dart';
import '../../domain/repositories/semantic_repository.dart';
import '../datasources/semantic_local_data_source.dart';
import '../models/ontology_model.dart';
import '../models/semantic_template_model.dart';
import '../models/semantic_annotation_model.dart';

class SemanticRepositoryImpl implements SemanticRepository {
  final SemanticLocalDataSource localDataSource;

  SemanticRepositoryImpl(this.localDataSource);

  // ============================================
  // Ontologia
  // ============================================

  @override
  Future<bool> saveOntology(Ontology ontology) async {
    final model = OntologyModel.fromEntity(ontology);
    return await localDataSource.saveOntology(model);
  }

  @override
  Future<Ontology?> getOntology(String id) async {
    final model = await localDataSource.getOntology(id);
    return model?.toEntity();
  }

  @override
  Future<List<Ontology>> getAllOntologies() async {
    final models = await localDataSource.getAllOntologies();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> deleteOntology(String id) async {
    return await localDataSource.deleteOntology(id);
  }

  @override
  Future<String> exportOntologyToOwl(String ontologyId) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) {
      throw Exception('Ontologia não encontrada: $ontologyId');
    }
    return ontology.toOwlXml();
  }

  @override
  Future<Ontology> importOntologyFromOwl(String owlXml) async {
    // Implementação simplificada - parsing básico
    // Em produção, usar um parser XML completo
    throw UnimplementedError('Import OWL não implementado nesta versão');
  }

  // ============================================
  // Classes
  // ============================================

  @override
  Future<bool> addClass(String ontologyId, OntologyClass ontologyClass) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) return false;

    final updatedOntology = ontology.copyWith(
      classes: [...ontology.classes, ontologyClass],
      updatedAt: DateTime.now(),
    );

    return await saveOntology(updatedOntology);
  }

  @override
  Future<bool> updateClass(String ontologyId, OntologyClass ontologyClass) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) return false;

    final updatedClasses = ontology.classes.map((c) {
      return c.uri == ontologyClass.uri ? ontologyClass : c;
    }).toList();

    final updatedOntology = ontology.copyWith(
      classes: updatedClasses,
      updatedAt: DateTime.now(),
    );

    return await saveOntology(updatedOntology);
  }

  @override
  Future<bool> removeClass(String ontologyId, String classUri) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) return false;

    final updatedClasses = ontology.classes
        .where((c) => c.uri != classUri)
        .toList();

    final updatedOntology = ontology.copyWith(
      classes: updatedClasses,
      updatedAt: DateTime.now(),
    );

    return await saveOntology(updatedOntology);
  }

  @override
  Future<List<OntologyClass>> getClassesByOntology(String ontologyId) async {
    final ontology = await getOntology(ontologyId);
    return ontology?.classes ?? [];
  }

  // ============================================
  // Propriedades
  // ============================================

  @override
  Future<bool> addProperty(String ontologyId, OntologyProperty property) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) return false;

    final updatedOntology = ontology.copyWith(
      properties: [...ontology.properties, property],
      updatedAt: DateTime.now(),
    );

    return await saveOntology(updatedOntology);
  }

  @override
  Future<bool> updateProperty(String ontologyId, OntologyProperty property) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) return false;

    final updatedProperties = ontology.properties.map((p) {
      return p.uri == property.uri ? property : p;
    }).toList();

    final updatedOntology = ontology.copyWith(
      properties: updatedProperties,
      updatedAt: DateTime.now(),
    );

    return await saveOntology(updatedOntology);
  }

  @override
  Future<bool> removeProperty(String ontologyId, String propertyUri) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) return false;

    final updatedProperties = ontology.properties
        .where((p) => p.uri != propertyUri)
        .toList();

    final updatedOntology = ontology.copyWith(
      properties: updatedProperties,
      updatedAt: DateTime.now(),
    );

    return await saveOntology(updatedOntology);
  }

  @override
  Future<List<OntologyProperty>> getPropertiesForClass(
    String ontologyId,
    String classUri,
  ) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) return [];

    return ontology.getPropertiesForClass(classUri);
  }

  // ============================================
  // Templates Semânticos
  // ============================================

  @override
  Future<bool> saveTemplate(SemanticTemplate template) async {
    final model = SemanticTemplateModel.fromEntity(template);
    return await localDataSource.saveTemplate(model);
  }

  @override
  Future<SemanticTemplate?> getTemplate(String id) async {
    final model = await localDataSource.getTemplate(id);
    return model?.toEntity();
  }

  @override
  Future<List<SemanticTemplate>> getAllTemplates() async {
    final models = await localDataSource.getAllTemplates();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SemanticTemplate>> getActiveTemplates() async {
    final models = await localDataSource.getActiveTemplates();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> deleteTemplate(String id) async {
    return await localDataSource.deleteTemplate(id);
  }

  @override
  Future<SemanticTemplate> createTemplateFromClass(
    String ontologyId,
    String classUri,
    String templateName,
  ) async {
    final ontology = await getOntology(ontologyId);
    if (ontology == null) {
      throw Exception('Ontologia não encontrada');
    }

    final mainClass = ontology.getClass(classUri);
    if (mainClass == null) {
      throw Exception('Classe não encontrada');
    }

    final properties = ontology.getPropertiesForClass(classUri);

    final template = SemanticTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: templateName,
      mainClass: mainClass,
      properties: properties,
      owlDefinition: ontology.toOwlXml(),
      createdAt: DateTime.now(),
    );

    await saveTemplate(template);
    return template;
  }

  // ============================================
  // Anotações Semânticas
  // ============================================

  @override
  Future<bool> saveAnnotation(SemanticAnnotation annotation) async {
    final model = SemanticAnnotationModel.fromEntity(annotation);
    return await localDataSource.saveAnnotation(model);
  }

  @override
  Future<SemanticAnnotation?> getAnnotation(String id) async {
    final model = await localDataSource.getAnnotation(id);
    return model?.toEntity();
  }

  @override
  Future<SemanticAnnotation?> getAnnotationByNoteId(String noteId) async {
    final model = await localDataSource.getAnnotationByNoteId(noteId);
    return model?.toEntity();
  }

  @override
  Future<List<SemanticAnnotation>> getAllAnnotations() async {
    final models = await localDataSource.getAllAnnotations();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SemanticAnnotation>> getAnnotationsByTemplate(String templateId) async {
    final models = await localDataSource.getAnnotationsByTemplate(templateId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SemanticAnnotation>> getAnnotationsByClass(String classUri) async {
    final models = await localDataSource.getAnnotationsByClass(classUri);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> deleteAnnotation(String id) async {
    return await localDataSource.deleteAnnotation(id);
  }

  @override
  Future<bool> deleteAnnotationByNoteId(String noteId) async {
    return await localDataSource.deleteAnnotationByNoteId(noteId);
  }

  // ============================================
  // Triplas RDF
  // ============================================

  @override
  Future<List<RdfTriple>> getAllTriples() async {
    final models = await localDataSource.getAllTriples();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<RdfTriple>> getTriplesForNote(String noteId) async {
    final subjectUri = 'http://meuapp.com/notes#$noteId';
    final models = await localDataSource.getTriplesBySubject(subjectUri);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> addTriple(RdfTriple triple) async {
    final model = RdfTripleModel.fromEntity(triple);
    return await localDataSource.saveTriple(model);
  }

  @override
  Future<bool> removeTriplesForNote(String noteId) async {
    final subjectUri = 'http://meuapp.com/notes#$noteId';
    return await localDataSource.removeTriplesBySubject(subjectUri);
  }

  // ============================================
  // Consultas SPARQL (Simplificado)
  // ============================================

  @override
  Future<List<Map<String, dynamic>>> executeSparqlSelect(String query) async {
    // Implementação simplificada de SPARQL
    final triples = await getAllTriples();
    final results = <Map<String, dynamic>>[];

    // Parser básico para queries simples
    // Suporta: SELECT ?s ?p ?o WHERE { ?s ?p ?o }
    final whereMatch = RegExp(r'WHERE\s*\{([^}]+)\}', caseSensitive: false)
        .firstMatch(query);
    
    if (whereMatch == null) return results;

    final pattern = whereMatch.group(1)?.trim() ?? '';
    final parts = pattern.split(RegExp(r'\s+'));

    if (parts.length < 3) return results;

    final sPattern = parts[0];
    final pPattern = parts[1];
    final oPattern = parts[2].replaceAll('.', '');

    for (final triple in triples) {
      final match = <String, dynamic>{};
      
      if (sPattern.startsWith('?')) {
        match[sPattern.substring(1)] = triple.subject;
      } else if (sPattern != triple.subject) {
        continue;
      }

      if (pPattern.startsWith('?')) {
        match[pPattern.substring(1)] = triple.predicate;
      } else if (pPattern != triple.predicate && !triple.predicate.contains(pPattern.replaceAll(':', ''))) {
        continue;
      }

      if (oPattern.startsWith('?')) {
        match[oPattern.substring(1)] = triple.object;
      } else if (oPattern != triple.object) {
        continue;
      }

      results.add(match);
    }

    return results;
  }

  @override
  Future<bool> executeSparqlAsk(String query) async {
    final results = await executeSparqlSelect(
      query.replaceFirst(RegExp(r'ASK', caseSensitive: false), 'SELECT *'),
    );
    return results.isNotEmpty;
  }

  @override
  Future<List<RdfTriple>> executeSparqlConstruct(String query) async {
    // Simplificado: retorna todas as triplas que correspondem
    final results = await executeSparqlSelect(query);
    final triples = <RdfTriple>[];

    for (final result in results) {
      if (result.containsKey('s') && result.containsKey('p') && result.containsKey('o')) {
        triples.add(RdfTriple(
          subject: result['s'] as String,
          predicate: result['p'] as String,
          object: result['o'] as String,
        ));
      }
    }

    return triples;
  }

  // ============================================
  // Inferência (Simplificado)
  // ============================================

  @override
  Future<List<RdfTriple>> runInference() async {
    final inferredTriples = <RdfTriple>[];
    final allTriples = await getAllTriples();
    final ontologies = await getAllOntologies();

    // Inferência de subclasses
    for (final ontology in ontologies) {
      for (final ontClass in ontology.classes) {
        if (ontClass.parentClassUri != null) {
          // Encontrar instâncias da subclasse
          for (final triple in allTriples) {
            if (triple.predicate.contains('type') && triple.object == ontClass.uri) {
              // Inferir que também é instância da classe pai
              final inferred = RdfTriple(
                subject: triple.subject,
                predicate: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
                object: ontClass.parentClassUri!,
                isLiteral: false,
              );
              
              if (!_tripleExists(allTriples, inferred) && 
                  !_tripleExists(inferredTriples, inferred)) {
                inferredTriples.add(inferred);
                await addTriple(inferred);
              }
            }
          }
        }
      }
    }

    return inferredTriples;
  }

  bool _tripleExists(List<RdfTriple> triples, RdfTriple triple) {
    return triples.any((t) =>
        t.subject == triple.subject &&
        t.predicate == triple.predicate &&
        t.object == triple.object);
  }

  @override
  Future<ConsistencyResult> checkConsistency() async {
    final inconsistencies = <String>[];
    final warnings = <String>[];
    final ontologies = await getAllOntologies();
    final annotations = await getAllAnnotations();

    for (final ontology in ontologies) {
      for (final ontClass in ontology.classes) {
        // Verificar restrições de cardinalidade
        for (final restriction in ontClass.restrictions) {
          if (restriction.type == RestrictionType.maxCardinality) {
            final maxCard = restriction.value as int;
            
            for (final annotation in annotations) {
              if (annotation.classUri == ontClass.uri) {
                final propValues = annotation.propertyValues[restriction.propertyUri];
                final relations = annotation.relations
                    .where((r) => r.propertyUri == restriction.propertyUri);
                
                int count = 0;
                if (propValues != null) count++;
                count += relations.length;

                if (count > maxCard) {
                  inconsistencies.add(
                    'Nota ${annotation.noteId} viola cardinalidade máxima de ${restriction.propertyUri}',
                  );
                }
              }
            }
          }
        }
      }
    }

    return ConsistencyResult(
      isConsistent: inconsistencies.isEmpty,
      inconsistencies: inconsistencies,
      warnings: warnings,
    );
  }

  @override
  Future<ValidationResult> validateInstance(String noteId, String classUri) async {
    final annotation = await getAnnotationByNoteId(noteId);
    if (annotation == null) {
      return ValidationResult(
        isValid: false,
        errors: ['Anotação não encontrada para nota $noteId'],
      );
    }

    final template = await getTemplate(annotation.templateId);
    if (template == null) {
      return ValidationResult(
        isValid: false,
        errors: ['Template não encontrado'],
      );
    }

    return template.validateValues(annotation.propertyValues);
  }
}
