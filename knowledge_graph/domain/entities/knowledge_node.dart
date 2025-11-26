import '../../../notes/domain/entities/graph.dart';

/// Nó de conhecimento com suporte semântico
/// Estende GraphNode com informações de ontologia
class KnowledgeNode extends GraphNode {
  /// URI da classe OWL (ex: http://meuapp.com/ontology#Aula)
  final String? ontologyClassUri;
  
  /// Propriedades semânticas extraídas da anotação
  final Map<String, dynamic> semanticProperties;
  
  /// Lista de URIs de relações inferidas pelo reasoner
  final List<String> inferredRelations;
  
  /// Se este nó foi inferido (não criado explicitamente)
  final bool isInferred;
  
  /// Nível na hierarquia de classes (0 = raiz)
  final int hierarchyLevel;
  
  /// URIs das classes pai (para navegação hierárquica)
  final List<String> parentClassUris;

  KnowledgeNode({
    required super.id,
    required super.label,
    required super.type,
    this.ontologyClassUri,
    this.semanticProperties = const {},
    this.inferredRelations = const [],
    this.isInferred = false,
    this.hierarchyLevel = 0,
    this.parentClassUris = const [],
    super.properties,
  });

  /// Verifica se o nó tem tipo semântico definido
  bool get hasSemanticType => ontologyClassUri != null;

  /// Retorna o nome local da classe OWL
  String? get classLocalName {
    if (ontologyClassUri == null) return null;
    if (ontologyClassUri!.contains('#')) {
      return ontologyClassUri!.split('#').last;
    }
    return ontologyClassUri!.split('/').last;
  }

  /// Cria cópia com valores alterados
  KnowledgeNode copyWith({
    String? id,
    String? label,
    String? type,
    String? ontologyClassUri,
    Map<String, dynamic>? semanticProperties,
    List<String>? inferredRelations,
    bool? isInferred,
    int? hierarchyLevel,
    List<String>? parentClassUris,
    Map<String, dynamic>? properties,
  }) {
    return KnowledgeNode(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      ontologyClassUri: ontologyClassUri ?? this.ontologyClassUri,
      semanticProperties: semanticProperties ?? this.semanticProperties,
      inferredRelations: inferredRelations ?? this.inferredRelations,
      isInferred: isInferred ?? this.isInferred,
      hierarchyLevel: hierarchyLevel ?? this.hierarchyLevel,
      parentClassUris: parentClassUris ?? this.parentClassUris,
      properties: properties ?? this.properties,
    );
  }

  @override
  String toString() => 
    'KnowledgeNode(id: $id, label: $label, class: $classLocalName, inferred: $isInferred)';
}

/// Aresta semântica com informações de predicado OWL
class SemanticEdge extends GraphEdge {
  /// URI da propriedade OWL que define esta relação
  final String predicateUri;
  
  /// Se a relação foi inferida pelo reasoner
  final bool isInferred;
  
  /// Label da propriedade (ex: "tem Professor")
  final String? predicateLabel;
  
  /// Tipo da propriedade (object ou data)
  final SemanticEdgeType edgeType;
  
  /// Peso da relação (para algoritmos de grafo)
  final double weight;

  SemanticEdge({
    required super.id,
    required super.sourceId,
    required super.targetId,
    required super.relationship,
    required this.predicateUri,
    this.isInferred = false,
    this.predicateLabel,
    this.edgeType = SemanticEdgeType.explicit,
    this.weight = 1.0,
    super.properties,
  });

  /// Retorna o nome local do predicado
  String get predicateLocalName {
    if (predicateUri.contains('#')) {
      return predicateUri.split('#').last;
    }
    return predicateUri.split('/').last;
  }

  /// Cria cópia com valores alterados
  SemanticEdge copyWith({
    String? id,
    String? sourceId,
    String? targetId,
    String? relationship,
    String? predicateUri,
    bool? isInferred,
    String? predicateLabel,
    SemanticEdgeType? edgeType,
    double? weight,
    Map<String, dynamic>? properties,
  }) {
    return SemanticEdge(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      relationship: relationship ?? this.relationship,
      predicateUri: predicateUri ?? this.predicateUri,
      isInferred: isInferred ?? this.isInferred,
      predicateLabel: predicateLabel ?? this.predicateLabel,
      edgeType: edgeType ?? this.edgeType,
      weight: weight ?? this.weight,
      properties: properties ?? this.properties,
    );
  }

  @override
  String toString() => 
    'SemanticEdge($sourceId -[$predicateLocalName]-> $targetId, inferred: $isInferred)';
}

/// Tipos de arestas semânticas
enum SemanticEdgeType {
  /// Relação explícita (definida pelo usuário)
  explicit,
  
  /// Relação inferida por herança de classe
  inheritedClass,
  
  /// Relação inferida por propriedade transitiva
  transitive,
  
  /// Relação inferida por propriedade inversa
  inverse,
  
  /// Relação baseada em tag compartilhada
  sharedTag,
  
  /// Relação baseada em link [[wiki]]
  wikiLink,
}

/// Grafo de conhecimento completo
class KnowledgeGraph {
  final String id;
  final List<KnowledgeNode> nodes;
  final List<SemanticEdge> edges;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final KnowledgeGraphStats? stats;

  KnowledgeGraph({
    required this.id,
    required this.nodes,
    required this.edges,
    this.metadata = const {},
    DateTime? createdAt,
    this.stats,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Busca nó por ID
  KnowledgeNode? getNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Busca nós por tipo semântico
  List<KnowledgeNode> getNodesByClass(String classUri) {
    return nodes.where((n) => n.ontologyClassUri == classUri).toList();
  }

  /// Busca nós inferidos
  List<KnowledgeNode> get inferredNodes => 
    nodes.where((n) => n.isInferred).toList();

  /// Busca arestas inferidas
  List<SemanticEdge> get inferredEdges => 
    edges.where((e) => e.isInferred).toList();

  /// Busca arestas de um nó (saindo)
  List<SemanticEdge> getOutgoingEdges(String nodeId) {
    return edges.where((e) => e.sourceId == nodeId).toList();
  }

  /// Busca arestas para um nó (chegando)
  List<SemanticEdge> getIncomingEdges(String nodeId) {
    return edges.where((e) => e.targetId == nodeId).toList();
  }

  /// Busca nós conectados a um nó
  List<KnowledgeNode> getConnectedNodes(String nodeId) {
    final connectedIds = <String>{};
    
    for (final edge in edges) {
      if (edge.sourceId == nodeId) {
        connectedIds.add(edge.targetId);
      } else if (edge.targetId == nodeId) {
        connectedIds.add(edge.sourceId);
      }
    }
    
    return nodes.where((n) => connectedIds.contains(n.id)).toList();
  }

  /// Cria cópia com valores alterados
  KnowledgeGraph copyWith({
    String? id,
    List<KnowledgeNode>? nodes,
    List<SemanticEdge>? edges,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    KnowledgeGraphStats? stats,
  }) {
    return KnowledgeGraph(
      id: id ?? this.id,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
    );
  }
}

/// Estatísticas do grafo de conhecimento
class KnowledgeGraphStats {
  final int totalNodes;
  final int totalEdges;
  final int inferredNodes;
  final int inferredEdges;
  final int semanticNodes;
  final int tagNodes;
  final Map<String, int> nodesByClass;
  final Map<String, int> edgesByPredicate;
  final double density;
  final int connectedComponents;

  KnowledgeGraphStats({
    required this.totalNodes,
    required this.totalEdges,
    required this.inferredNodes,
    required this.inferredEdges,
    required this.semanticNodes,
    required this.tagNodes,
    required this.nodesByClass,
    required this.edgesByPredicate,
    required this.density,
    required this.connectedComponents,
  });

  factory KnowledgeGraphStats.fromGraph(KnowledgeGraph graph) {
    final nodesByClass = <String, int>{};
    final edgesByPredicate = <String, int>{};
    int semanticNodes = 0;
    int tagNodes = 0;

    for (final node in graph.nodes) {
      if (node.ontologyClassUri != null) {
        semanticNodes++;
        final className = node.classLocalName ?? 'Unknown';
        nodesByClass[className] = (nodesByClass[className] ?? 0) + 1;
      }
      if (node.type == 'tag') tagNodes++;
    }

    for (final edge in graph.edges) {
      final predName = edge.predicateLocalName;
      edgesByPredicate[predName] = (edgesByPredicate[predName] ?? 0) + 1;
    }

    final n = graph.nodes.length;
    final density = n > 1 ? (2 * graph.edges.length) / (n * (n - 1)) : 0.0;

    return KnowledgeGraphStats(
      totalNodes: graph.nodes.length,
      totalEdges: graph.edges.length,
      inferredNodes: graph.inferredNodes.length,
      inferredEdges: graph.inferredEdges.length,
      semanticNodes: semanticNodes,
      tagNodes: tagNodes,
      nodesByClass: nodesByClass,
      edgesByPredicate: edgesByPredicate,
      density: density,
      connectedComponents: 1, // Simplificado
    );
  }
}
