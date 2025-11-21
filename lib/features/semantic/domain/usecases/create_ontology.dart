import '../../../../core/usecases/usecase.dart';
import '../entities/ontology.dart';
import '../repositories/semantic_repository.dart';

/// Parâmetros para criar uma ontologia
class CreateOntologyParams {
  final String name;
  final String? description;
  final String? baseUri;

  CreateOntologyParams({
    required this.name,
    this.description,
    this.baseUri,
  });
}

/// Caso de uso para criar uma nova ontologia
class CreateOntology implements UseCase<Ontology, CreateOntologyParams> {
  final SemanticRepository repository;

  CreateOntology(this.repository);

  @override
  Future<Ontology> call(CreateOntologyParams params) async {
    // Gerar URI base se não fornecido
    final baseUri = params.baseUri ?? 
        'http://meuapp.com/ontology/${_slugify(params.name)}#';

    // Criar ontologia
    final ontology = Ontology(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      baseUri: baseUri,
      name: params.name,
      description: params.description,
      createdAt: DateTime.now(),
    );

    // Salvar no repositório
    final success = await repository.saveOntology(ontology);
    
    if (!success) {
      throw Exception('Falha ao salvar ontologia');
    }

    return ontology;
  }

  /// Converte nome para slug (URL-friendly)
  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
