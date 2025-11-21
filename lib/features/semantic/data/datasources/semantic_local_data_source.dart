import '../models/ontology_model.dart';
import '../models/semantic_template_model.dart';
import '../models/semantic_annotation_model.dart';

/// Interface abstrata para operações locais de dados semânticos
abstract class SemanticLocalDataSource {
  // ============================================
  // Ontologias
  // ============================================
  
  /// Salva uma ontologia
  Future<bool> saveOntology(OntologyModel ontology);
  
  /// Recupera uma ontologia por ID
  Future<OntologyModel?> getOntology(String id);
  
  /// Recupera todas as ontologias
  Future<List<OntologyModel>> getAllOntologies();
  
  /// Deleta uma ontologia
  Future<bool> deleteOntology(String id);
  
  /// Atualiza uma ontologia
  Future<bool> updateOntology(OntologyModel ontology);

  // ============================================
  // Templates Semânticos
  // ============================================
  
  /// Salva um template
  Future<bool> saveTemplate(SemanticTemplateModel template);
  
  /// Recupera um template por ID
  Future<SemanticTemplateModel?> getTemplate(String id);
  
  /// Recupera todos os templates
  Future<List<SemanticTemplateModel>> getAllTemplates();
  
  /// Recupera templates ativos
  Future<List<SemanticTemplateModel>> getActiveTemplates();
  
  /// Deleta um template
  Future<bool> deleteTemplate(String id);
  
  /// Atualiza um template
  Future<bool> updateTemplate(SemanticTemplateModel template);

  // ============================================
  // Anotações Semânticas
  // ============================================
  
  /// Salva uma anotação
  Future<bool> saveAnnotation(SemanticAnnotationModel annotation);
  
  /// Recupera uma anotação por ID
  Future<SemanticAnnotationModel?> getAnnotation(String id);
  
  /// Recupera anotação por ID da nota
  Future<SemanticAnnotationModel?> getAnnotationByNoteId(String noteId);
  
  /// Recupera todas as anotações
  Future<List<SemanticAnnotationModel>> getAllAnnotations();
  
  /// Recupera anotações por template
  Future<List<SemanticAnnotationModel>> getAnnotationsByTemplate(String templateId);
  
  /// Recupera anotações por classe
  Future<List<SemanticAnnotationModel>> getAnnotationsByClass(String classUri);
  
  /// Deleta uma anotação
  Future<bool> deleteAnnotation(String id);
  
  /// Deleta anotação por ID da nota
  Future<bool> deleteAnnotationByNoteId(String noteId);

  // ============================================
  // Triplas RDF
  // ============================================
  
  /// Salva uma tripla
  Future<bool> saveTriple(RdfTripleModel triple);
  
  /// Recupera todas as triplas
  Future<List<RdfTripleModel>> getAllTriples();
  
  /// Recupera triplas por sujeito
  Future<List<RdfTripleModel>> getTriplesBySubject(String subjectUri);
  
  /// Recupera triplas por predicado
  Future<List<RdfTripleModel>> getTriplesByPredicate(String predicateUri);
  
  /// Recupera triplas por objeto (URI ou literal)
  Future<List<RdfTripleModel>> getTriplesByObject(String object);
  
  /// Remove triplas por sujeito
  Future<bool> removeTriplesBySubject(String subjectUri);
  
  /// Remove todas as triplas
  Future<bool> clearAllTriples();
}
