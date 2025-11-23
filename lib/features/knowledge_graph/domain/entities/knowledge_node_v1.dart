// lib/features/knowledge_graph/domain/entities/knowledge_node.dart
class KnowledgeNode extends GraphNode {
  final String? ontologyClassUri;  // Tipo semântico
  final Map<String, dynamic> semanticProperties;
  final List<String> inferredRelations; // Relações inferidas pelo reasoner
  
  KnowledgeNode({
    required super.id,
    required super.label,
    required super.type,
    this.ontologyClassUri,
    this.semanticProperties = const {},
    this.inferredRelations = const [],
    super.properties,
  });
}

// Tipos de relações semânticas
class SemanticEdge extends GraphEdge {
  final String predicateUri;  // URI da propriedade OWL
  final bool isInferred;      // Foi inferido pelo reasoner?
  
  SemanticEdge({
    required super.id,
    required super.sourceId,
    required super.targetId,
    required super.relationship,
    required this.predicateUri,
    this.isInferred = false,
    super.properties,
  });
}
