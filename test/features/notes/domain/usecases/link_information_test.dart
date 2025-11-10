import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/note.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/graph.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/repositories/note_repository.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/usecases/link_information.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late LinkInformation usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = LinkInformation(mockRepository);
  });

  final tNotes = [
    Note(
      id: '1',
      content: '# Nota 1\n\nReferencia [[nota-2]] e [[nota-3]]',
      metadata: {
        'title': 'Nota 1',
        'links': ['nota-2', 'nota-3'],
      },
    ),
    Note(
      id: '2',
      content: '# Nota 2\n\nReferencia [[nota-1]]',
      metadata: {
        'title': 'Nota 2',
        'links': ['nota-1'],
      },
    ),
    Note(
      id: '3',
      content: '# Nota 3\n\nSem links',
      metadata: {
        'title': 'Nota 3',
        'links': [],
      },
    ),
  ];

  final tGraph = Graph(
    id: 'graph-1',
    nodes: [
      GraphNode(id: '1', label: 'Nota 1', type: 'note'),
      GraphNode(id: '2', label: 'Nota 2', type: 'note'),
      GraphNode(id: '3', label: 'Nota 3', type: 'note'),
    ],
    edges: [
      GraphEdge(
        id: 'edge-1',
        sourceId: '1',
        targetId: '2',
        relationship: 'references',
      ),
      GraphEdge(
        id: 'edge-2',
        sourceId: '1',
        targetId: '3',
        relationship: 'references',
      ),
      GraphEdge(
        id: 'edge-3',
        sourceId: '2',
        targetId: '1',
        relationship: 'references',
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(tNotes);
  });

  test('deve criar conexões entre notas baseado nos links', () async {
    when(() => mockRepository.linkNotes(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tNotes);

    expect(result.nodes.length, equals(3));
    expect(result.edges.length, equals(3));
    verify(() => mockRepository.linkNotes(tNotes)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('deve criar nós para cada nota', () async {
    when(() => mockRepository.linkNotes(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tNotes);

    expect(result.nodes.any((node) => node.id == '1'), isTrue);
    expect(result.nodes.any((node) => node.id == '2'), isTrue);
    expect(result.nodes.any((node) => node.id == '3'), isTrue);
  });

  test('deve criar arestas baseadas nos links internos', () async {
    when(() => mockRepository.linkNotes(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tNotes);

    expect(
      result.edges.any((edge) => edge.sourceId == '1' && edge.targetId == '2'),
      isTrue,
    );
    expect(
      result.edges.any((edge) => edge.sourceId == '1' && edge.targetId == '3'),
      isTrue,
    );
  });

  test('deve identificar relações bidirecionais', () async {
    when(() => mockRepository.linkNotes(any()))
        .thenAnswer((_) async => tGraph);

    final result = await usecase(tNotes);

    final edge1to2 = result.edges.any(
      (edge) => edge.sourceId == '1' && edge.targetId == '2',
    );
    final edge2to1 = result.edges.any(
      (edge) => edge.sourceId == '2' && edge.targetId == '1',
    );

    expect(edge1to2 && edge2to1, isTrue);
  });
}
