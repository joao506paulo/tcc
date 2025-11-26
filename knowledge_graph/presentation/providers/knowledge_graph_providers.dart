// lib/features/knowledge_graph/presentation/providers/knowledge_graph_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/knowledge_node.dart';
import '../../domain/repositories/knowledge_graph_repository.dart';
import '../../domain/repositories/knowledge_graph_repository_impl.dart';
import '../../../notes/domain/repositories/note_repository.dart';
import '../../../semantic/domain/repositories/semantic_repository.dart';
import '../../../../core/injection/injection_container.dart' as di;

// IMPORTANTE: Adicionar ao injection_container.dart:
// import '../../features/knowledge_graph/domain/repositories/knowledge_graph_repository.dart';
// import '../../features/knowledge_graph/domain/repositories/knowledge_graph_repository_impl.dart';
// 
// sl.registerLazySingleton<KnowledgeGraphRepository>(
//   () => KnowledgeGraphRepositoryImpl(
//     noteRepository: sl(),
//     semanticRepository: sl(),
//   ),
// );

// Repository Provider
final knowledgeGraphRepositoryProvider = Provider<KnowledgeGraphRepository>((ref) {
  return KnowledgeGraphRepositoryImpl(
    noteRepository: di.sl<NoteRepository>(),
    semanticRepository: di.sl<SemanticRepository>(),
  );
});

// Controller para gerenciar o Knowledge Graph
class KnowledgeGraphController extends StateNotifier<AsyncValue<KnowledgeGraph?>> {
  final KnowledgeGraphRepository repository;

  KnowledgeGraphController(this.repository) : super(const AsyncValue.data(null));

  Future<void> generateGraph({
    bool includeInferred = true,
    bool includeTags = true,
    bool includeWikiLinks = true,
    List<String>? filterByClasses,
  }) async {
    state = const AsyncValue.loading();
    try {
      final graph = await repository.generateKnowledgeGraph(
        includeInferred: includeInferred,
        includeTags: includeTags,
        includeWikiLinks: includeWikiLinks,
        filterByClasses: filterByClasses,
      );
      
      // Calcular estatísticas
      final stats = KnowledgeGraphStats.fromGraph(graph);
      final graphWithStats = graph.copyWith(stats: stats);
      
      state = AsyncValue.data(graphWithStats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<KnowledgeNode>> findSimilar(String nodeId) async {
    try {
      return await repository.findSimilarNodes(nodeId);
    } catch (e) {
      return [];
    }
  }

  Future<List<ClassHierarchyNode>> getHierarchy() async {
    try {
      return await repository.getClassHierarchy();
    } catch (e) {
      return [];
    }
  }
}

// Provider do Controller
final knowledgeGraphControllerProvider = 
    StateNotifierProvider<KnowledgeGraphController, AsyncValue<KnowledgeGraph?>>((ref) {
  return KnowledgeGraphController(
    ref.watch(knowledgeGraphRepositoryProvider),
  );
});

// Provider para estatísticas
final knowledgeGraphStatsProvider = Provider<KnowledgeGraphStats?>((ref) {
  final graphState = ref.watch(knowledgeGraphControllerProvider);
  return graphState.maybeWhen(
    data: (graph) => graph?.stats,
    orElse: () => null,
  );
});
