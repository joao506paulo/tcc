import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class ReadMarkdown implements UseCase<Note, String> {
  final NoteRepository repository;

  ReadMarkdown(this.repository);

  @override
  Future<Note> call(String path) async {
    return await repository.readMarkdown(path);
  }
}
