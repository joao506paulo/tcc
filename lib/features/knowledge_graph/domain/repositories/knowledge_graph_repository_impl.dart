import '../../../notes/domain/repositories/note_repository.dart';
import '../../../semantic/domain/repositories/semantic_repository.dart';
import '../../../semantic/domain/entities/semantic_annotation.dart';
import '../../domain/entities/knowledge_node.dart';
import '../../domain/repositories/knowledge_graph_repository.dart';

class KnowledgeGraphRepositoryImpl implements KnowledgeGraphRepository {
  final NoteRepository noteRepository;
  final SemanticRepository semanticRepository;

  KnowledgeGraphRepositoryImpl({
    required this.noteRepository,
    required this.semanticRepository,
  });

  @override
  Future<KnowledgeGraph> generateKnowledgeGraph({
    bool includeInferred = true,
    bool includeTags = true,
    bool includeWikiLinks = true,
    List<String>? filterByClasses,
  }) async {
    final nodes = <KnowledgeNode>[];
    final edges = <SemanticEdge>[];
    int edgeCounter = 0;

    // 1. Buscar todas as notas
    final notes = await noteRepository.getAllNotes();
    
    // 2. Buscar todas as anotações semânticas
    final annotations = await semanticRepository.getAllAnnotations();
    final annotationMap = <String, SemanticAnnotation>{};
    for (final ann in annotations) {
      annotationMap[ann.noteId] = ann;
    }

    // 3. Buscar ontologias para hierarquia
    final ontologies = await semanticRepository.getAllOntologies();
    final classHierarchy = <String, String?>{};
    final classLabels = <String, String>{};
    
    for (final ont in ontologies) {
      for (final c in ont.classes) {
        classHierarchy[c.uri] = c.parentClassUri;
        classLabels[c.uri] = c.label;
      }
    }

    // 4. Criar nós para cada nota
    for (final note in notes) {
      final annotation = annotationMap[note.id];
      final tags = note.metadata['tags'] as List? ?? [];
      final links = note.metadata['links'] as List? ?? [];
      final title = note.metadata['title'] as String? ?? 'Sem título';

      // Filtrar por classe se especificado
      if (filterByClasses != null && annotation != null) {
        if (!filterByClasses.contains(annotation.classUri)) {
          continue;
        }
      }

      // Calcular nível na hierarquia
      int hierarchyLevel = 0;
      final parentUris = <String>[];
      if (annotation != null) {
        String? currentClass = annotation.classUri;
        while (currentClass != null && classHierarchy.containsKey(currentClass)) {
          final parent = classHierarchy[currentClass];
          if (parent != null) {
            parentUris.add(parent);
            hierarchyLevel++;
          }
          currentClass = parent;
        }
      }

      // Criar nó de conhecimento
      final node = KnowledgeNode(
        id: note.id,
        label: title,
        type: annotation != null ? 'semantic_note' : 'note',
        ontologyClassUri: annotation?.classUri,
        semanticProperties: annotation?.propertyValues ?? {},
        inferredRelations: [],
        isInferred: false,
        hierarchyLevel: hierarchyLevel,
        parentClassUris: parentUris,
        properties: {
          'word_count': note.metadata['word_count'] ?? 0,
          'created_at': note.metadata['created_at'],
          'tags': tags,
          'links': links,
        },
      );
      nodes.add(node);

      // 5. Criar arestas semânticas (ObjectProperties)
      if (annotation != null) {
        for (final relation in annotation.relations) {
          edges.add(SemanticEdge(
            id: 'edge-${edgeCounter++}',
            sourceId: note.id,
            targetId: relation.targetNoteId,
            relationship: relation.label ?? relation.propertyUri.split('#').last,
            predicateUri: relation.propertyUri,
            predicateLabel: relation.label,
            isInferred: false,
            edgeType: SemanticEdgeType.explicit,
          ));
        }
      }

      // 6. Criar arestas de wiki links
      if (includeWikiLinks) {
        for (final link in links) {
          final targetNote = notes.firstWhere(
            (n) => n.metadata['title'] == link || n.id == link,
            orElse: () => notes.first,
          );
          
          if (targetNote.id != note.id) {
            edges.add(SemanticEdge(
              id: 'edge-${edgeCounter++}',
              sourceId: note.id,
              targetId: targetNote.id,
              relationship: 'links_to',
              predicateUri: 'http://meuapp.com/ontology#linksTo',
              isInferred: false,
              edgeType: SemanticEdgeType.wikiLink,
            ));
          }
        }
      }
    }

    // 7. Criar nós de tags
    if (includeTags) {
      final allTags = <String>{};
      for (final note in notes) {
        final tags = note.metadata['tags'] as List? ?? [];
        allTags.addAll(tags.cast<String>());
      }

      for (final tag in allTags) {
        nodes.add(KnowledgeNode(
          id: 'tag-$tag',
          label: '#$tag',
          type: 'tag',
          isInferred: false,
          properties: {'tag_name': tag},
        ));

        // Conectar notas às tags
        for (final note in notes) {
          final tags = note.metadata['tags'] as List? ?? [];
          if (tags.contains(tag)) {
            edges.add(SemanticEdge(
              id: 'edge-${edgeCounter++}',
              sourceId: note.id,
              targetId: 'tag-$tag',
              relationship: 'has_tag',
              predicateUri: 'http://meuapp.com/ontology#hasTag',
              isInferred: false,
              edgeType: SemanticEdgeType.sharedTag,
            ));
          }
        }
      }
    }

    // 8. Executar inferência se habilitado
    if (includeInferred) {
      final inferredEdges = await _runInference(nodes, edges, classHierarchy);
      edges.addAll(inferredEdges);
    }

    return KnowledgeGraph(
      id: 'kg-${DateTime.now().millisecondsSinceEpoch}',
      nodes: nodes,
      edges: edges,
      metadata: {
        'includeInferred': includeInferred,
        'includeTags': includeTags,
        'includeWikiLinks': includeWikiLinks,
        'filterByClasses': filterByClasses,
      },
    );
  }

  Future<List<SemanticEdge>> _runInference(
    List<KnowledgeNode> nodes,
    List<SemanticEdge> existingEdges,
    Map<String, String?> classHierarchy,
  ) async {
    final inferredEdges = <SemanticEdge>[];
    int edgeCounter = existingEdges.length;

    // Inferência 1: Notas da mesma classe são relacionadas
    final nodesByClass = <String, List<KnowledgeNode>>{};
    for (final node in nodes) {
      if (node.ontologyClassUri != null) {
        nodesByClass.putIfAbsent(node.ontologyClassUri!, () => []).add(node);
      }
    }

    // Inferência 2: Se A é subclasse de B, instâncias de A também são B
    for (final node in nodes) {
      if (node.ontologyClassUri != null) {
        String? parentClass = classHierarchy[node.ontologyClassUri!];
        while (parentClass != null) {
          // Criar relação implícita "é tipo de"
          inferredEdges.add(SemanticEdge(
            id: 'inferred-${edgeCounter++}',
            sourceId: node.id,
            targetId: 'class-$parentClass',
            relationship: 'instance_of',
            predicateUri: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
            isInferred: true,
            edgeType: SemanticEdgeType.inheritedClass,
          ));
          parentClass = classHierarchy[parentClass];
        }
      }
    }

    // Inferência 3: Tags compartilhadas implicam relação
    final tagNodes = nodes.where((n) => n.type == 'tag').toList();
    for (final tagNode in tagNodes) {
      final connectedNotes = existingEdges
          .where((e) => e.targetId == tagNode.id && e.relationship == 'has_tag')
          .map((e) => e.sourceId)
          .toList();

      // Criar relações "relacionado por tag" entre notas
      for (int i = 0; i < connectedNotes.length; i++) {
        for (int j = i + 1; j < connectedNotes.length; j++) {
          // Evitar duplicatas
          final exists = existingEdges.any((e) =>
              (e.sourceId == connectedNotes[i] && e.targetId == connectedNotes[j]) ||
              (e.sourceId == connectedNotes[j] && e.targetId == connectedNotes[i]));
          
          if (!exists) {
            inferredEdges.add(SemanticEdge(
              id: 'inferred-${edgeCounter++}',
              sourceId: connectedNotes[i],
              targetId: connectedNotes[j],
              relationship: 'related_by_tag',
              predicateUri: 'http://meuapp.com/ontology#relatedByTag',
              isInferred: true,
              edgeType: SemanticEdgeType.sharedTag,
              weight: 0.5,
            ));
          }
        }
      }
    }

    return inferredEdges;
  }

  @override
  Future<List<KnowledgeNode>> getNodesByClass(String classUri) async {
    final graph = await generateKnowledgeGraph(includeInferred: false);
    return graph.getNodesByClass(classUri);
  }

  @override
  Future<List<KnowledgeNode>> getConnectedNodes(
    String nodeId, {
    int maxDepth = 1,
    List<String>? predicateFilter,
  }) async {
    final graph = await generateKnowledgeGraph();
    final result = <KnowledgeNode>[];
    final visited = <String>{nodeId};
    var currentLevel = [nodeId];

    for (int depth = 0; depth < maxDepth && currentLevel.isNotEmpty; depth++) {
      final nextLevel = <String>[];
      
      for (final id in currentLevel) {
        final edges = [...graph.getOutgoingEdges(id), ...graph.getIncomingEdges(id)];
        
        for (final edge in edges) {
          if (predicateFilter != null && !predicateFilter.contains(edge.predicateUri)) {
            continue;
          }
          
          final connectedId = edge.sourceId == id ? edge.targetId : edge.sourceId;
          
          if (!visited.contains(connectedId)) {
            visited.add(connectedId);
            nextLevel.add(connectedId);
            
            final node = graph.getNode(connectedId);
            if (node != null) result.add(node);
          }
        }
      }
      
      currentLevel = nextLevel;
    }

    return result;
  }

  @override
  Future<List<SemanticEdge>?> findPath(
    String sourceNodeId,
    String targetNodeId, {
    int maxDepth = 5,
  }) async {
    final graph = await generateKnowledgeGraph();
    
    // BFS para encontrar caminho mais curto
    final visited = <String>{sourceNodeId};
    final queue = <List<SemanticEdge>>[[]];
    final nodeQueue = <String>[sourceNodeId];

    while (nodeQueue.isNotEmpty && queue.first.length < maxDepth) {
      final currentNode = nodeQueue.removeAt(0);
      final currentPath = queue.removeAt(0);

      final edges = [...graph.getOutgoingEdges(currentNode), ...graph.getIncomingEdges(currentNode)];
      
      for (final edge in edges) {
        final nextNode = edge.sourceId == currentNode ? edge.targetId : edge.sourceId;
        
        if (nextNode == targetNodeId) {
          return [...currentPath, edge];
        }
        
        if (!visited.contains(nextNode)) {
          visited.add(nextNode);
          nodeQueue.add(nextNode);
          queue.add([...currentPath, edge]);
        }
      }
    }

    return null;
  }

  @override
  Future<KnowledgeGraph> querySubgraph({
    String? classFilter,
    String? predicateFilter,
    Map<String, dynamic>? propertyFilters,
  }) async {
    final fullGraph = await generateKnowledgeGraph();
    
    var filteredNodes = fullGraph.nodes.toList();
    var filteredEdges = fullGraph.edges.toList();

    if (classFilter != null) {
      filteredNodes = filteredNodes
          .where((n) => n.ontologyClassUri == classFilter)
          .toList();
      
      final nodeIds = filteredNodes.map((n) => n.id).toSet();
      filteredEdges = filteredEdges
          .where((e) => nodeIds.contains(e.sourceId) || nodeIds.contains(e.targetId))
          .toList();
    }

    if (predicateFilter != null) {
      filteredEdges = filteredEdges
          .where((e) => e.predicateUri == predicateFilter)
          .toList();
    }

    if (propertyFilters != null) {
      filteredNodes = filteredNodes.where((n) {
        for (final entry in propertyFilters.entries) {
          if (n.semanticProperties[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    return fullGraph.copyWith(
      nodes: filteredNodes,
      edges: filteredEdges,
    );
  }

  @override
  Future<List<SemanticEdge>> runInference() async {
    final graph = await generateKnowledgeGraph(includeInferred: true);
    return graph.inferredEdges;
  }

  @override
  Future<KnowledgeGraphStats> calculateStats() async {
    final graph = await generateKnowledgeGraph();
    return KnowledgeGraphStats.fromGraph(graph);
  }

  @override
  Future<List<ClassHierarchyNode>> getClassHierarchy() async {
    final ontologies = await semanticRepository.getAllOntologies();
    final hierarchy = <ClassHierarchyNode>[];
    final annotations = await semanticRepository.getAllAnnotations();

    // Contar instâncias por classe
    final instanceCount = <String, int>{};
    for (final ann in annotations) {
      instanceCount[ann.classUri] = (instanceCount[ann.classUri] ?? 0) + 1;
    }

    for (final ont in ontologies) {
      final rootClasses = ont.rootClasses;
      
      for (final rootClass in rootClasses) {
        hierarchy.add(_buildHierarchyNode(
          ont,
          rootClass.uri,
          rootClass.label,
          null,
          0,
          instanceCount,
        ));
      }
    }

    return hierarchy;
  }

  ClassHierarchyNode _buildHierarchyNode(
    dynamic ontology,
    String classUri,
    String label,
    String? parentUri,
    int level,
    Map<String, int> instanceCount,
  ) {
    final subclasses = ontology.getSubclasses(classUri);
    final children = subclasses.map((sub) => _buildHierarchyNode(
      ontology,
      sub.uri,
      sub.label,
      classUri,
      level + 1,
      instanceCount,
    )).toList();

    return ClassHierarchyNode(
      classUri: classUri,
      label: label,
      parentUri: parentUri,
      children: children,
      instanceCount: instanceCount[classUri] ?? 0,
      level: level,
    );
  }

  @override
  Future<List<KnowledgeNode>> findSimilarNodes(
    String nodeId, {
    double minSimilarity = 0.5,
  }) async {
    final graph = await generateKnowledgeGraph();
    final sourceNode = graph.getNode(nodeId);
    
    if (sourceNode == null) return [];

    final similarities = <KnowledgeNode, double>{};

    for (final node in graph.nodes) {
      if (node.id == nodeId) continue;

      double similarity = 0;
      int factors = 0;

      // Similaridade por classe
      if (sourceNode.ontologyClassUri != null && 
          node.ontologyClassUri == sourceNode.ontologyClassUri) {
        similarity += 0.4;
        factors++;
      }

      // Similaridade por tags compartilhadas
      final sourceTags = (sourceNode.properties['tags'] as List?)?.cast<String>() ?? [];
      final nodeTags = (node.properties['tags'] as List?)?.cast<String>() ?? [];
      if (sourceTags.isNotEmpty && nodeTags.isNotEmpty) {
        final sharedTags = sourceTags.where((t) => nodeTags.contains(t)).length;
        final tagSimilarity = sharedTags / (sourceTags.length + nodeTags.length - sharedTags);
        similarity += tagSimilarity * 0.3;
        factors++;
      }

      // Similaridade por conexões compartilhadas
      final sourceConnected = graph.getConnectedNodes(sourceNode.id).map((n) => n.id).toSet();
      final nodeConnected = graph.getConnectedNodes(node.id).map((n) => n.id).toSet();
      if (sourceConnected.isNotEmpty && nodeConnected.isNotEmpty) {
        final sharedConnections = sourceConnected.intersection(nodeConnected).length;
        final connectionSimilarity = sharedConnections / 
            (sourceConnected.length + nodeConnected.length - sharedConnections);
        similarity += connectionSimilarity * 0.3;
        factors++;
      }

      if (factors > 0) {
        similarities[node] = similarity / factors * factors;
      }
    }

    return similarities.entries
        .where((e) => e.value >= minSimilarity)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => (similarities[b] ?? 0).compareTo(similarities[a] ?? 0));
  }
}
