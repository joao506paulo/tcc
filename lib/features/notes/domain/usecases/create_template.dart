import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class TemplateParams {
  final String templateType;
  final Map<String, String> variables;

  TemplateParams({
    required this.templateType,
    this.variables = const {},
  });
}

class CreateTemplate implements UseCase<Note, TemplateParams> {
  final NoteRepository repository;

  CreateTemplate(this.repository);

  @override
  Future<Note> call(TemplateParams params) async {
    return await repository.createFromTemplate(params);
  }
}
