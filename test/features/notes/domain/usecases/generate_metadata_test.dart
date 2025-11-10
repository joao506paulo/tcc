import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/note.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/repositories/note_repository.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/usecases/generate_metadata.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late GenerateMetadata usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = GenerateMetadata(mockRepository);
  });

  final tNote = Note(
    id: '1',
    content: '''# Título Principal

Este é um texto sobre **Flutter** e #programacao.

Links: [[outra-nota]], [[conceito-importante]]

Tags: #flutter #mobile #desenvolvimento
''',
    metadata: {},
  );

  final tNoteWithMetadata = Note(
    id: '1',
    content: tNote.content,
    metadata: {
      'title': 'Título Principal',
      'tags': ['programacao', 'flutter', 'mobile', 'desenvolvimento'],
      'links': ['outra-nota', 'conceito-importante'],
      'word_count': 12,
      'created_at': '2025-11-10',
    },
  );

  test('deve gerar metadados a partir do conteúdo da nota', () async {
    when(() => mockRepository.generateMetadata(any()))
        .thenAnswer((_) async => tNoteWithMetadata);

    final result = await usecase(tNote);

    expect(result.metadata['title'], equals('Título Principal'));
    expect(result.metadata['tags'], isA<List>());
    expect(result.metadata['tags'], contains('flutter'));
    expect(result.metadata['links'], isA<List>());
    expect(result.metadata['links'], contains('outra-nota'));
    verify(() => mockRepository.generateMetadata(tNote)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('deve extrair título do primeiro heading H1', () async {
    when(() => mockRepository.generateMetadata(any()))
        .thenAnswer((_) async => tNoteWithMetadata);

    final result = await usecase(tNote);

    expect(result.metadata['title'], equals('Título Principal'));
  });

  test('deve extrair todas as tags do formato #tag', () async {
    when(() => mockRepository.generateMetadata(any()))
        .thenAnswer((_) async => tNoteWithMetadata);

    final result = await usecase(tNote);

    expect(result.metadata['tags'], containsAll(['programacao', 'flutter', 'mobile', 'desenvolvimento']));
  });

  test('deve extrair links internos no formato [[link]]', () async {
    when(() => mockRepository.generateMetadata(any()))
        .thenAnswer((_) async => tNoteWithMetadata);

    final result = await usecase(tNote);

    expect(result.metadata['links'], containsAll(['outra-nota', 'conceito-importante']));
  });
}
