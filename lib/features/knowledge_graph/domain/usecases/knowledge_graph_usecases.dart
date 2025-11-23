import '../../../../core/usecases/usecase.dart';
import '../entities/knowledge_node.dart';
import '../repositories/knowledge_graph_repository.dart';

/// Parâmetros para geração do knowledge graph
class GenerateKnowledgeGraphParams {
  final bool includeInferred;
  final bool includeTags;
  final bool includeWikiLinks;
  final List<String>? filterByClasses;
  final bool calculateStats;

  GenerateKnowledgeGraphParams({
    this.includeInferred = true,
    this.includeTags = true,
    this.includeWikiLinks = true,
    this.filterByClasses,
    this.calculateStats = true,
  });
}

/// Caso de uso para gerar grafo de conhecimento
class GenerateKnowledgeGraph 
    implements UseCase<KnowledgeGraph, GenerateKnowledgeGraphParams> {
  final KnowledgeGraphRepository repository;

  GenerateKnowledgeGraph(this.repository);

  @override
  Future<KnowledgeGraph> call(GenerateKnowledgeGraphParams params) async {
    var graph = await repository.generateKnowledgeGraph(
      includeInferred: params.includeInferred,
      includeTags: params.includeTags,
      includeWikiLinks: params.includeWikiLinks,
      filterByClasses: params.filterByClasses,
    );

    if (params.calculateStats) {
      final stats = KnowledgeGraphStats.fromGraph(graph);
      graph = graph.copyWith(stats: stats);
    }

    return graph;
  }
}

/// Caso de uso para buscar nós conectados
class GetConnectedNodes 
    implements UseCase<List<KnowledgeNode>, GetConnectedNodesParams> {
  final KnowledgeGraphRepository repository;

  GetConnectedNodes(this.repository);

  @override
  Future<List<KnowledgeNode>> call(GetConnectedNodesParams params) async {
    return await repository.getConnectedNodes(
      params.nodeId,
      maxDepth: params.maxDepth,
      predicateFilter: params.predicateFilter,
    );
  }
}

class GetConnectedNodesParams {
  final String nodeId;
  final int maxDepth;
  final List<String>? predicateFilter;

  GetConnectedNodesParams({
    required this.nodeId,
    this.maxDepth = 1,
    this.predicateFilter,
  });
}

/// Caso de uso para executar inferência
class RunGraphInference implements UseCase<List<SemanticEdge>, void> {
  final KnowledgeGraphRepository repository;

  RunGraphInference(this.repository);

  @override
  Future<List<SemanticEdge>> call(void params) async {
    return await repository.runInference();
  }
}

/// Caso de uso para buscar hierarquia de classes
class GetClassHierarchy implements UseCase<List<ClassHierarchyNode>, void> {
  final KnowledgeGraphRepository repository;

  GetClassHierarchy(this.repository);

  @override
  Future<List<ClassHierarchyNode>> call(void params) async {
    return await repository.getClassHierarchy();
  }
}

/// Caso de uso para encontrar caminho entre nós
class FindPathBetweenNodes 
    implements UseCase<List<SemanticEdge>?, FindPathParams> {
  final KnowledgeGraphRepository repository;

  FindPathBetweenNodes(this.repository);

  @override
  Future<List<SemanticEdge>?> call(FindPathParams params) async {
    return await repository.findPath(
      params.sourceNodeId,
      params.targetNodeId,
      maxDepth: params.maxDepth,
    );
  }
}

class FindPathParams {
  final String sourceNodeId;
  final String targetNodeId;
  final int maxDepth;

  FindPathParams({
    required this.sourceNodeId,
    required this.targetNodeId,
    this.maxDepth = 5,
  });
}

/// Caso de uso para buscar nós similares
class FindSimilarNodes 
    implements UseCase<List<KnowledgeNode>, FindSimilarParams> {
  final KnowledgeGraphRepository repository;

  FindSimilarNodes(this.repository);

  @override
  Future<List<KnowledgeNode>> call(FindSimilarParams params) async {
    return await repository.findSimilarNodes(
      params.nodeId,
      minSimilarity: params.minSimilarity,
    );
  }
}

class FindSimilarParams {
  final String nodeId;
  final double minSimilarity;

  FindSimilarParams({
    required this.nodeId,
    this.minSimilarity = 0.5,
  });
}
