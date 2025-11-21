import '../../../../core/usecases/usecase.dart';
import '../entities/semantic_template.dart';
import '../repositories/semantic_repository.dart';

/// Parâmetros para buscar templates (pode ser vazio para buscar todos)
class GetSemanticTemplatesParams {
  final bool activeOnly;
  final String? ontologyId;

  GetSemanticTemplatesParams({
    this.activeOnly = true,
    this.ontologyId,
  });
}

/// Caso de uso para buscar templates semânticos
class GetSemanticTemplates implements UseCase<List<SemanticTemplate>, GetSemanticTemplatesParams> {
  final SemanticRepository repository;

  GetSemanticTemplates(this.repository);

  @override
  Future<List<SemanticTemplate>> call(GetSemanticTemplatesParams params) async {
    List<SemanticTemplate> templates;
    
    if (params.activeOnly) {
      templates = await repository.getActiveTemplates();
    } else {
      templates = await repository.getAllTemplates();
    }

    // Filtrar por ontologia se especificado
    if (params.ontologyId != null) {
      templates = templates.where((t) {
        return t.mainClass.uri.contains(params.ontologyId!);
      }).toList();
    }

    // Ordenar por nome
    templates.sort((a, b) => a.name.compareTo(b.name));

    return templates;
  }
}

/// Caso de uso sem parâmetros para buscar todos os templates ativos
class GetActiveTemplates implements UseCase<List<SemanticTemplate>, void> {
  final SemanticRepository repository;

  GetActiveTemplates(this.repository);

  @override
  Future<List<SemanticTemplate>> call(void params) async {
    final templates = await repository.getActiveTemplates();
    templates.sort((a, b) => a.name.compareTo(b.name));
    return templates;
  }
}

/// Caso de uso para buscar um template específico por ID
class GetSemanticTemplate implements UseCase<SemanticTemplate?, String> {
  final SemanticRepository repository;

  GetSemanticTemplate(this.repository);

  @override
  Future<SemanticTemplate?> call(String templateId) async {
    return await repository.getTemplate(templateId);
  }
}
