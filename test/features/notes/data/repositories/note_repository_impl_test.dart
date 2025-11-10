import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/note.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/graph.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/usecases/create_graph.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/usecases/create_template.dart';
import 'package:flutter_clean_tdd_app/features/notes/data/datasources/note_local_data_source.dart';
import 'package:flutter_clean_tdd_app/features/notes/data/models/note_model.dart';
import 'package:flutter_clean_tdd_app/features/notes/data/models/graph_model.dart';
import 'package:flutter_clean_tdd_app/features/notes/data/repositories/note_repository_impl.dart';

class MockNoteLocalDataSource extends Mock implements NoteLocalDataSource {}

void main() {
  late NoteRepositoryImpl repository;
  late MockNoteLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockNoteLocalDataSource();
    repository = NoteRepositoryImpl(mockDataSource);
  });

  group('generateMetadata', () {
    test('deve extrair título do primeiro H1', () async {
      final note = Note(
        id: '1',
        content: '# Título Principal\n\nConteúdo',
        metadata: {},
      );

      final result = await repository.generateMetadata(note);

      expect(result.metadata['title'], equals('Título Principal'));
    });

    test('deve extrair todas as tags', () async {
      final note = Note(
        id: '1',
        content: 'Texto com #flutter e #dart e #mobile',
        metadata: {},
      );

      final result = await repository.generateMetadata(note);

      expect(result.metadata['tags'], isA<List>());
      expect(result.metadata['tags'], containsAll(['flutter', 'dart', 'mobile']));
    });

    test('deve extrair links internos', () async {
      final note = Note(
        id: '1',
        content: 'Link para [[nota-1]] e [[nota-2]]',
        metadata: {},
      );

      final result = await repository.generateMetadata(note);

      expect(result.metadata['links'], isA<List>());
      expect(result.metadata['links'], containsAll(['nota-1', 'nota-2']));
    });

    test('deve contar palavras corretamente', () async {
      final note = Note(
        id: '1',
        content: 'Um dois três quatro cinco',
        metadata: {},
      );

      final result = await repository.generateMetadata(note);

      expect(result.metadata['word_count'], equals(5));
    });

    test('deve adicionar timestamp de criação', () async {
      final note = Note(
        id: '1',
        content: 'Conteúdo',
        metadata: {},
      );

      final result = await repository.generateMetadata(note);

      expect(result.metadata['created_at'], isNotNull);
      expect(result.metadata['created_at'], isA<String>());
    });
  });

  group('storeNote', () {
    final tNote = Note(
      id: '1',
      content: 'Conteúdo',
      metadata: {'title': 'Teste'},
    );

    setUpAll(() {
      registerFallbackValue(NoteModel.fromEntity(tNote));
    });

    test('deve chamar o data source para salvar a nota', () async {
      when(() => mockDataSource.saveNote(any()))
          .thenAnswer((_) async => true);

      final result = await repository.storeNote(tNote);

      expect(result, isTrue);
      verify(() => mockDataSource.saveNote(any())).called(1);
    });

    test('deve retornar false quando falhar', () async {
      when(() => mockDataSource.saveNote(any()))
          .thenAnswer((_) async => false);

      final result = await repository.storeNote(tNote);

      expect(result, isFalse);
    });
  });

  group('getNote', () {
    final tNoteModel = NoteModel(
      id: '1',
      content: 'Conteúdo',
      metadata: {'title': 'Teste'},
    );

    test('deve retornar uma nota quando encontrada', () async {
      when(() => mockDataSource.getNote(any()))
          .thenAnswer((_) async => tNoteModel);

      final result = await repository.getNote('1');

      expect(result, isNotNull);
      expect(result?.id, equals('1'));
      verify(() => mockDataSource.getNote('1')).called(1);
    });

    test('deve retornar null quando não encontrada', () async {
      when(() => mockDataSource.getNote(any()))
          .thenAnswer((_) async => null);

      final result = await repository.getNote('999');

      expect(result, isNull);
    });
  });

  group('getAllNotes', () {
    final tNoteModels = [
      NoteModel(id: '1', content: 'Nota 1', metadata: {}),
      NoteModel(id: '2', content: 'Nota 2', metadata: {}),
    ];

    test('deve retornar lista de notas', () async {
      when(() => mockDataSource.getAllNotes())
          .thenAnswer((_) async => tNoteModels);

      final result = await repository.getAllNotes();

      expect(result.length, equals(2));
      expect(result[0].id, equals('1'));
      expect(result[1].id, equals('2'));
    });

    test('deve retornar lista vazia quando não há notas', () async {
      when(() => mockDataSource.getAllNotes())
          .thenAnswer((_) async => []);

      final result = await repository.getAllNotes();

      expect(result, isEmpty);
    });
  });

  group('deleteNote', () {
    test('deve deletar nota com sucesso', () async {
      when(() => mockDataSource.deleteNote(any()))
          .thenAnswer((_) async => true);

      final result = await repository.deleteNote('1');

      expect(result, isTrue);
      verify(() => mockDataSource.deleteNote('1')).called(1);
    });

    test('deve retornar false quando falhar', () async {
      when(() => mockDataSource.deleteNote(any()))
          .thenAnswer((_) async => false);

      final result = await repository.deleteNote('999');

      expect(result, isFalse);
    });
  });

  group('linkNotes', () {
    final tNotes = [
      Note(
        id: '1',
        content: 'Nota 1',
        metadata: {
          'title': 'Nota 1',
          'links': ['Nota 2'],
        },
      ),
      Note(
        id: '2',
        content: 'Nota 2',
        metadata: {
          'title': 'Nota 2',
          'links': [],
        },
      ),
    ];

    test('deve criar grafo com nós para cada nota', () async {
      final result = await repository.linkNotes(tNotes);

      expect(result.nodes.length, equals(2));
      expect(result.nodes.any((node) => node.id == '1'), isTrue);
      expect(result.nodes.any((node) => node.id == '2'), isTrue);
    });

    test('deve criar arestas baseadas nos links', () async {
      final result = await repository.linkNotes(tNotes);

      expect(result.edges.isNotEmpty, isTrue);
      expect(
        result.edges.any((edge) => 
          edge.sourceId == '1' && edge.targetId == '2'),
        isTrue,
      );
    });

    test('deve incluir metadados no grafo', () async {
      final result = await repository.linkNotes(tNotes);

      expect(result.metadata, isNotEmpty);
      expect(result.metadata['node_count'], equals(2));
      expect(result.metadata['edge_count'], isNotNull);
    });
  });

  group('createSemanticGraph', () {
    final tParams = CreateGraphParams(
      notes: [
        Note(
          id: '1',
          content: '# Flutter',
          metadata: {
            'title': 'Flutter',
            'tags': ['mobile'],
            'links': [],
          },
        ),
      ],
      includeTagNodes: true,
      includeLinkNodes: true,
    );

    setUpAll(() {
      registerFallbackValue(
        GraphModel(id: 'test', nodes: [], edges: []),
      );
    });

    test('deve criar grafo semântico completo', () async {
      when(() => mockDataSource.saveGraph(any()))
          .thenAnswer((_) async => true);

      final result = await repository.createSemanticGraph(tParams);

      expect(result.nodes.isNotEmpty, isTrue);
      expect(result.metadata, isNotEmpty);
      verify(() => mockDataSource.saveGraph(any())).called(1);
    });

    test('deve incluir nós de tags quando habilitado', () async {
      when(() => mockDataSource.saveGraph(any()))
          .thenAnswer((_) async => true);

      final result = await repository.createSemanticGraph(tParams);

      final tagNodes = result.nodes.where((node) => node.type == 'tag');
      expect(tagNodes.isNotEmpty, isTrue);
    });

    test('deve criar arestas has_tag entre notas e tags', () async {
      when(() => mockDataSource.saveGraph(any()))
          .thenAnswer((_) async => true);

      final result = await repository.createSemanticGraph(tParams);

      final hasTagEdges = result.edges
          .where((edge) => edge.relationship == 'has_tag');
      expect(hasTagEdges.isNotEmpty, isTrue);
    });
  });

  group('createFromTemplate', () {
    test('deve criar nota de template daily-note', () async {
      final params = TemplateParams(
        templateType: 'daily-note',
        variables: {
          'date': '2025-11-10',
          'day_of_week': 'Segunda-feira',
        },
      );

      final result = await repository.createFromTemplate(params);

      expect(result.content, contains('2025-11-10'));
      expect(result.content, contains('Segunda-feira'));
      expect(result.content, contains('Tarefas'));
      expect(result.metadata['template'], equals('daily-note'));
    });

    test('deve criar nota de template project', () async {
      final params = TemplateParams(
        templateType: 'project',
        variables: {
          'project_name': 'Meu Projeto',
          'start_date': '2025-11-10',
        },
      );

      final result = await repository.createFromTemplate(params);

      expect(result.content, contains('Meu Projeto'));
      expect(result.content, contains('Objetivo'));
      expect(result.metadata['template'], equals('project'));
      expect(result.metadata['type'], equals('project'));
    });

    test('deve criar nota de template meeting', () async {
      final params = TemplateParams(
        templateType: 'meeting',
        variables: {
          'meeting_title': 'Reunião de Planejamento',
          'date': '2025-11-10',
          'participants': 'João, Maria',
        },
      );

      final result = await repository.createFromTemplate(params);

      expect(result.content, contains('Reunião de Planejamento'));
      expect(result.content, contains('Pauta'));
      expect(result.content, contains('João, Maria'));
      expect(result.metadata['template'], equals('meeting'));
    });
  });

  group('getAvailableTemplates', () {
    test('deve retornar lista de templates disponíveis', () async {
      final result = await repository.getAvailableTemplates();

      expect(result, isA<List<String>>());
      expect(result, contains('daily-note'));
      expect(result, contains('project'));
      expect(result, contains('meeting'));
    });
  });
}
