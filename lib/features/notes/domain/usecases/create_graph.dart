import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../entities/graph.dart';
import '../repositories/note_repository.dart';

class CreateGraphParams {
  final List<Note> notes;
  final bool includeTagNodes;
  final bool includeLinkNodes;

  CreateGraphParams({
    required this.notes,
    this.includeTagNodes = true,
    this.includeLinkNodes = true,
  });
}

class CreateGraph implements UseCase<Graph, CreateGraphParams> {
  final NoteRepository repository;

  CreateGraph(this.repository);

  @override
  Future<Graph> call(CreateGraphParams params) async {
    return await repository.createSemanticGraph(params);
  }
}
