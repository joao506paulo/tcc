import '../../../../core/usecases/usecase.dart';
import '../entities/ontology.dart';
import '../entities/ontology_property.dart';
import '../repositories/semantic_repository.dart';

/// Parâmetros para adicionar uma propriedade a uma ontologia
class AddOntologyPropertyParams {
  final String ontologyId;
  final String label;
  final String? description;
  final PropertyType type;
  final String domainClassUri;
  final String rangeUri; // Classe URI ou XSD datatype
  final bool isRequired;
  final bool isFunctional;
  final String? inversePropertyUri;

  AddOntologyPropertyParams({
    required this.ontologyId,
    required this.label,
    this.description,
    required this.type,
    required this.domainClassUri,
    required this.rangeUri,
    this.isRequired = false,
    this.isFunctional = false,
    this.inversePropertyUri,
  });
}

/// Caso de uso para adicionar uma propriedade a uma ontologia
class AddOntologyProperty implements UseCase<OntologyProperty, AddOntologyPropertyParams> {
  final SemanticRepository repository;

  AddOntologyProperty(this.repository);

  @override
  Future<OntologyProperty> call(AddOntologyPropertyParams params) async {
    // Buscar ontologia
    final ontology = await repository.getOntology(params.ontologyId);
    
    if (ontology == null) {
      throw Exception('Ontologia não encontrada: ${params.ontologyId}');
    }

    // Verificar se a classe domínio existe
    final domainClass = ontology.getClass(params.domainClassUri);
    if (domainClass == null) {
      throw Exception('Classe domínio não encontrada: ${params.domainClassUri}');
    }

    // Se for ObjectProperty, verificar se a classe range existe
    if (params.type == PropertyType.objectProperty) {
      final rangeClass = ontology.getClass(params.rangeUri);
      if (rangeClass == null && !params.rangeUri.startsWith('http://www.w3.org')) {
        throw Exception('Classe range não encontrada: ${params.rangeUri}');
      }
    }

    // Gerar URI da propriedade
    final localName = _toPropertyName(params.label);
    final propertyUri = '${ontology.baseUri}$localName';

    // Verificar se já existe
    if (ontology.getProperty(propertyUri) != null) {
      throw Exception('Propriedade já existe: $propertyUri');
    }

    // Criar propriedade
    final property = OntologyProperty(
      uri: propertyUri,
      label: params.label,
      description: params.description,
      type: params.type,
      domainUri: params.domainClassUri,
      rangeUri: params.rangeUri,
      isRequired: params.isRequired,
      isFunctional: params.isFunctional,
      inversePropertyUri: params.inversePropertyUri,
    );

    // Adicionar à ontologia
    final success = await repository.addProperty(params.ontologyId, property);
    
    if (!success) {
      throw Exception('Falha ao adicionar propriedade');
    }

    // Atualizar lista de propriedades da classe domínio
    final updatedClass = domainClass.copyWith(
      propertyUris: [...domainClass.propertyUris, propertyUri],
    );
    await repository.updateClass(params.ontologyId, updatedClass);

    return property;
  }

  /// Converte label para nome de propriedade (camelCase com prefixo)
  String _toPropertyName(String label) {
    final normalized = label
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c');
    
    final words = normalized.split(RegExp(r'[^a-zA-Z0-9]'));
    
    if (words.isEmpty) return 'property';
    
    final first = words.first.toLowerCase();
    final rest = words
        .skip(1)
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
    
    return [first, ...rest].join();
  }
}
