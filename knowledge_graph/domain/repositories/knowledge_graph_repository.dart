import '../entities/knowledge_node.dart';

/// Repositório para operações do Knowledge Graph
abstract class KnowledgeGraphRepository {
  /// Gera grafo de conhecimento completo
  Future<KnowledgeGraph> generateKnowledgeGraph({
    bool includeInferred = true,
    bool includeTags = true,
    bool includeWikiLinks = true,
    List<String>? filterByClasses,
  });

  /// Busca nós por classe semântica
  Future<List<KnowledgeNode>> getNodesByClass(String classUri);

  /// Busca nós conectados a um nó específico
  Future<List<KnowledgeNode>> getConnectedNodes(
    String nodeId, {
    int maxDepth = 1,
    List<String>? predicateFilter,
  });

  /// Busca caminho entre dois nós
  Future<List<SemanticEdge>?> findPath(
    String sourceNodeId,
    String targetNodeId, {
    int maxDepth = 5,
  });

  /// Busca subgrafo por consulta semântica
  Future<KnowledgeGraph> querySubgraph({
    String? classFilter,
    String? predicateFilter,
    Map<String, dynamic>? propertyFilters,
  });

  /// Executa inferência e retorna novas relações
  Future<List<SemanticEdge>> runInference();

  /// Calcula estatísticas do grafo
  Future<KnowledgeGraphStats> calculateStats();

  /// Busca hierarquia de classes
  Future<List<ClassHierarchyNode>> getClassHierarchy();

  /// Busca nós similares baseado em propriedades
  Future<List<KnowledgeNode>> findSimilarNodes(
    String nodeId, {
    double minSimilarity = 0.5,
  });
}

/// Nó da hierarquia de classes
class ClassHierarchyNode {
  final String classUri;
  final String label;
  final String? parentUri;
  final List<ClassHierarchyNode> children;
  final int instanceCount;
  final int level;

  ClassHierarchyNode({
    required this.classUri,
    required this.label,
    this.parentUri,
    this.children = const [],
    this.instanceCount = 0,
    this.level = 0,
  });

  bool get hasChildren => children.isNotEmpty;
  bool get isRoot => parentUri == null;

  ClassHierarchyNode copyWith({
    String? classUri,
    String? label,
    String? parentUri,
    List<ClassHierarchyNode>? children,
    int? instanceCount,
    int? level,
  }) {
    return ClassHierarchyNode(
      classUri: classUri ?? this.classUri,
      label: label ?? this.label,
      parentUri: parentUri ?? this.parentUri,
      children: children ?? this.children,
      instanceCount: instanceCount ?? this.instanceCount,
      level: level ?? this.level,
    );
  }
}
