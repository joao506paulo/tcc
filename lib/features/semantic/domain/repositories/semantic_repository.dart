import '../entities/ontology.dart';
import '../entities/ontology_class.dart';
import '../entities/ontology_property.dart';
import '../entities/semantic_template.dart';
import '../entities/semantic_annotation.dart';

/// Repositório abstrato para operações semânticas
abstract class SemanticRepository {
  // ============================================
  // Ontologia
  // ============================================
  
  /// Salva uma ontologia
  Future<bool> saveOntology(Ontology ontology);
  
  /// Recupera uma ontologia por ID
  Future<Ontology?> getOntology(String id);
  
  /// Recupera todas as ontologias
  Future<List<Ontology>> getAllOntologies();
  
  /// Deleta uma ontologia
  Future<bool> deleteOntology(String id);
  
  /// Exporta ontologia para OWL/XML
  Future<String> exportOntologyToOwl(String ontologyId);
  
  /// Importa ontologia de OWL/XML
  Future<Ontology> importOntologyFromOwl(String owlXml);

  // ============================================
  // Classes
  // ============================================
  
  /// Adiciona uma classe a uma ontologia
  Future<bool> addClass(String ontologyId, OntologyClass ontologyClass);
  
  /// Atualiza uma classe
  Future<bool> updateClass(String ontologyId, OntologyClass ontologyClass);
  
  /// Remove uma classe de uma ontologia
  Future<bool> removeClass(String ontologyId, String classUri);
  
  /// Busca classes por ontologia
  Future<List<OntologyClass>> getClassesByOntology(String ontologyId);

  // ============================================
  // Propriedades
  // ============================================
  
  /// Adiciona uma propriedade a uma ontologia
  Future<bool> addProperty(String ontologyId, OntologyProperty property);
  
  /// Atualiza uma propriedade
  Future<bool> updateProperty(String ontologyId, OntologyProperty property);
  
  /// Remove uma propriedade de uma ontologia
  Future<bool> removeProperty(String ontologyId, String propertyUri);
  
  /// Busca propriedades de uma classe (incluindo herdadas)
  Future<List<OntologyProperty>> getPropertiesForClass(
    String ontologyId,
    String classUri,
  );

  // ============================================
  // Templates Semânticos
  // ============================================
  
  /// Salva um template semântico
  Future<bool> saveTemplate(SemanticTemplate template);
  
  /// Recupera um template por ID
  Future<SemanticTemplate?> getTemplate(String id);
  
  /// Recupera todos os templates
  Future<List<SemanticTemplate>> getAllTemplates();
  
  /// Recupera templates ativos
  Future<List<SemanticTemplate>> getActiveTemplates();
  
  /// Deleta um template
  Future<bool> deleteTemplate(String id);
  
  /// Cria template a partir de uma classe
  Future<SemanticTemplate> createTemplateFromClass(
    String ontologyId,
    String classUri,
    String templateName,
  );

  // ============================================
  // Anotações Semânticas
  // ============================================
  
  /// Salva uma anotação semântica
  Future<bool> saveAnnotation(SemanticAnnotation annotation);
  
  /// Recupera anotação por ID
  Future<SemanticAnnotation?> getAnnotation(String id);
  
  /// Recupera anotação de uma nota
  Future<SemanticAnnotation?> getAnnotationByNoteId(String noteId);
  
  /// Recupera todas as anotações
  Future<List<SemanticAnnotation>> getAllAnnotations();
  
  /// Recupera anotações por template
  Future<List<SemanticAnnotation>> getAnnotationsByTemplate(String templateId);
  
  /// Recupera anotações por classe
  Future<List<SemanticAnnotation>> getAnnotationsByClass(String classUri);
  
  /// Deleta uma anotação
  Future<bool> deleteAnnotation(String id);
  
  /// Deleta anotação de uma nota
  Future<bool> deleteAnnotationByNoteId(String noteId);

  // ============================================
  // Triplas RDF
  // ============================================
  
  /// Recupera todas as triplas RDF
  Future<List<RdfTriple>> getAllTriples();
  
  /// Recupera triplas de uma nota
  Future<List<RdfTriple>> getTriplesForNote(String noteId);
  
  /// Adiciona tripla
  Future<bool> addTriple(RdfTriple triple);
  
  /// Remove triplas de uma nota
  Future<bool> removeTriplesForNote(String noteId);

  // ============================================
  // Consultas SPARQL
  // ============================================
  
  /// Executa uma query SPARQL SELECT
  Future<List<Map<String, dynamic>>> executeSparqlSelect(String query);
  
  /// Executa uma query SPARQL ASK
  Future<bool> executeSparqlAsk(String query);
  
  /// Executa uma query SPARQL CONSTRUCT
  Future<List<RdfTriple>> executeSparqlConstruct(String query);

  // ============================================
  // Inferência (Reasoner)
  // ============================================
  
  /// Executa inferência e retorna novas triplas inferidas
  Future<List<RdfTriple>> runInference();
  
  /// Verifica consistência da ontologia
  Future<ConsistencyResult> checkConsistency();
  
  /// Verifica se uma instância satisfaz as restrições de uma classe
  Future<ValidationResult> validateInstance(
    String noteId,
    String classUri,
  );
}

/// Resultado de verificação de consistência
class ConsistencyResult {
  final bool isConsistent;
  final List<String> inconsistencies;
  final List<String> warnings;

  ConsistencyResult({
    required this.isConsistent,
    this.inconsistencies = const [],
    this.warnings = const [],
  });
}
