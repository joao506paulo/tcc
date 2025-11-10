import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/note.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/graph.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/repositories/note_repository.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/usecases/create_graph.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late CreateGraph usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = CreateGraph(mockRepository);
  });

  final tParams = CreateGraphParams(
    notes: [
      Note(
        id: '1',
        content: '# Flutter\n\nFramework para #mobile',
        metadata: {
          'title': 'Flutter',
          'tags': ['mobile'],
          'links': ['dart'],
        },
      ),
      Note(
        id: '2',
        content: '# Dart\n\nLinguagem de #programacao',
        metadata: {
          'title': 'Dart',
          'tags': ['programacao'],
          'links': [],
        },
      ),
    ],
    includeTagNodes: true,
    includeLinkNodes: true,
  );

  final tGraph = Graph(
    id: 'semantic-graph-1',
    nodes: [
      GraphNode(id: '1', label: 'Flutter', type: 'note'),
      GraphNode(id: '2', label: 'Dart', type: 'note'),
      GraphNode(id: 'tag-mobile', label: 'mobile', type: 'tag'),
      GraphNode(id: 'tag-programacao', label: 'programacao', type: 'tag'),
    ],
    edges: [
      GraphEdge(
        id: 'edge-1',
        sourceId: '1',
        targetId: '2',
        relationship: 'links_to',
      ),
      GraphEdge(
        id: 'edge-2',
        sourceId: '1',
        targetId: 'tag-mobile',
        relationship: 'has_tag',
      ),
      GraphEdge(
        id: 'edge-3',
        sourceId: '2',
        targetId: 'tag-programacao',
        relationship: 'has_tag',
      ),
    ],
    metadata: {
      'created_at': '2025-11-10',
      'node_count': 4,
      'edge_count': 3,
    },
  );

  setUpAll(() {
    registerFallbackValue(tParams);
  });

  test('deve criar um grafo semântico completo a partir das notas', () async {
    when(() => mockRepository.createSemanticGraph(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tParams);

    expect(result.nodes.length, greaterThan(0));
    expect(result.edges.length, greaterThan(0));
    verify(() => mockRepository.createSemanticGraph(tParams)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('deve incluir nós de notas no grafo', () async {
    when(() => mockRepository.createSemanticGraph(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tParams);

    final noteNodes = result.nodes.where((node) => node.type == 'note');
    expect(noteNodes.length, equals(2));
  });

  test('deve incluir nós de tags quando habilitado', () async {
    when(() => mockRepository.createSemanticGraph(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tParams);

    final tagNodes = result.nodes.where((node) => node.type == 'tag');
    expect(tagNodes.isNotEmpty, isTrue);
  });

  test('deve criar arestas representando relações semânticas', () async {
    when(() => mockRepository.createSemanticGraph(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tParams);

    expect(result.edges.any((edge) => edge.relationship == 'links_to'), isTrue);
    expect(result.edges.any((edge) => edge.relationship == 'has_tag'), isTrue);
  });

  test('deve incluir metadados do grafo', () async {
    when(() => mockRepository.createSemanticGraph(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tParams);

    expect(result.metadata, isNotEmpty);
    expect(result.metadata['node_count'], equals(4));
    expect(result.metadata['edge_count'], equals(3));
  });

  test('deve permitir filtrar tipos de nós a incluir', () async {
    final paramsNoTags = CreateGraphParams(
      notes: tParams.notes,
      includeTagNodes: false,
      includeLinkNodes: true,
    );

    final graphNoTags = Graph(
      id: 'graph-2',
      nodes: [
        GraphNode(id: '1', label: 'Flutter', type: 'note'),
        GraphNode(id: '2', label: 'Dart', type: 'note'),
      ],
      edges: [
        GraphEdge(
          id: 'edge-1',
          sourceId: '1',
          targetId: '2',
          relationship: 'links_to',
        ),
      ],
    );

    when(() => mockRepository.createSemanticGraph(any()))
        .thenAnswer((_) async => graphNoTags);

    final result = await usecase(paramsNoTags);

    final tagNodes = result.nodes.where((node) => node.type == 'tag');
    expect(tagNodes.isEmpty, isTrue);
  });
}
