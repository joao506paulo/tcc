import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/note.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/repositories/note_repository.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/usecases/read_markdown.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late ReadMarkdown usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = ReadMarkdown(mockRepository);
  });

  const tPath = 'notes/example.md';
  final tNote = Note(
    id: '1',
    content: '# Exemplo\n\nTexto de teste',
    metadata: {'title': 'Exemplo'},
  );

  test('deve retornar uma Note com metadados ao ler o markdown', () async {
    when(() => mockRepository.readMarkdown(any()))
        .thenAnswer((_) async => tNote);

    final result = await usecase(tPath);

    expect(result, equals(tNote));
    verify(() => mockRepository.readMarkdown(tPath)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
