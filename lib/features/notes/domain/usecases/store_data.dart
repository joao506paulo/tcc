import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class StoreData implements UseCase<bool, Note> {
  final NoteRepository repository;

  StoreData(this.repository);

  @override
  Future<bool> call(Note note) async {
    return await repository.storeNote(note);
  }
}
