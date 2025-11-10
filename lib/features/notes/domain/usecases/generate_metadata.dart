import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GenerateMetadata implements UseCase<Note, Note> {
  final NoteRepository repository;

  GenerateMetadata(this.repository);

  @override
  Future<Note> call(Note note) async {
    return await repository.generateMetadata(note);
  }
}
