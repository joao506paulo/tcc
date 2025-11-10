import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/note.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/repositories/note_repository.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/usecases/store_data.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late StoreData usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = StoreData(mockRepository);
  });

  final tNote = Note(
    id: '1',
    content: '# Teste\n\nConteúdo de teste',
    metadata: {
      'title': 'Teste',
      'tags': ['teste', 'exemplo'],
      'created_at': '2025-11-10',
    },
  );

  setUpAll(() {
    registerFallbackValue(tNote);
  });

  test('deve armazenar a nota com sucesso', () async {
    when(() => mockRepository.storeNote(any()))
        .thenAnswer((_) async => true);

    final result = await usecase(tNote);

    expect(result, equals(true));
    verify(() => mockRepository.storeNote(tNote)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('deve retornar false quando falhar ao armazenar', () async {
    when(() => mockRepository.storeNote(any()))
        .thenAnswer((_) async => false);

    final result = await usecase(tNote);

    expect(result, equals(false));
    verify(() => mockRepository.storeNote(tNote)).called(1);
  });

  test('deve atualizar nota existente', () async {
    final updatedNote = Note(
      id: '1',
      content: '# Teste Atualizado\n\nConteúdo modificado',
      metadata: {
        'title': 'Teste Atualizado',
        'tags': ['teste', 'atualizado'],
        'updated_at': '2025-11-10',
      },
    );

    when(() => mockRepository.storeNote(any()))
        .thenAnswer((_) async => true);

    final result = await usecase(updatedNote);

    expect(result, equals(true));
    verify(() => mockRepository.storeNote(updatedNote)).called(1);
  });
}
