import '../../../../core/usecases/usecase.dart';
import '../entities/ontology.dart';
import '../entities/ontology_class.dart';
import '../repositories/semantic_repository.dart';

/// Parâmetros para adicionar uma classe a uma ontologia
class AddOntologyClassParams {
  final String ontologyId;
  final String label;
  final String? description;
  final String? parentClassUri;
  final List<OntologyRestriction> restrictions;

  AddOntologyClassParams({
    required this.ontologyId,
    required this.label,
    this.description,
    this.parentClassUri,
    this.restrictions = const [],
  });
}

/// Caso de uso para adicionar uma classe a uma ontologia
class AddOntologyClass implements UseCase<OntologyClass, AddOntologyClassParams> {
  final SemanticRepository repository;

  AddOntologyClass(this.repository);

  @override
  Future<OntologyClass> call(AddOntologyClassParams params) async {
    // Buscar ontologia
    final ontology = await repository.getOntology(params.ontologyId);
    
    if (ontology == null) {
      throw Exception('Ontologia não encontrada: ${params.ontologyId}');
    }

    // Gerar URI da classe
    final localName = _toLocalName(params.label);
    final classUri = '${ontology.baseUri}$localName';

    // Verificar se já existe
    if (ontology.getClass(classUri) != null) {
      throw Exception('Classe já existe: $classUri');
    }

    // Verificar se a classe pai existe (se especificada)
    if (params.parentClassUri != null) {
      final parentClass = ontology.getClass(params.parentClassUri!);
      if (parentClass == null) {
        throw Exception('Classe pai não encontrada: ${params.parentClassUri}');
      }
    }

    // Criar classe
    final ontologyClass = OntologyClass(
      uri: classUri,
      label: params.label,
      description: params.description,
      parentClassUri: params.parentClassUri,
      restrictions: params.restrictions,
    );

    // Adicionar à ontologia
    final success = await repository.addClass(params.ontologyId, ontologyClass);
    
    if (!success) {
      throw Exception('Falha ao adicionar classe');
    }

    return ontologyClass;
  }

  /// Converte label para nome local (PascalCase)
  String _toLocalName(String label) {
    final words = label
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .split(RegExp(r'[^a-zA-Z0-9]'));
    
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join();
  }
}
