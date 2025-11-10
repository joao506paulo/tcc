import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../entities/graph.dart';
import '../repositories/note_repository.dart';

class LinkInformation implements UseCase<Graph, List<Note>> {
  final NoteRepository repository;

  LinkInformation(this.repository);

  @override
  Future<Graph> call(List<Note> notes) async {
    return await repository.linkNotes(notes);
  }
}
