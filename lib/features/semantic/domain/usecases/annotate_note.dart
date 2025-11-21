import '../../../../core/usecases/usecase.dart';
import '../entities/semantic_annotation.dart';
import '../entities/semantic_template.dart';
import '../repositories/semantic_repository.dart';

/// Parâmetros para anotar uma nota semanticamente
class AnnotateNoteParams {
  final String noteId;
  final String templateId;
  final Map<String, dynamic> propertyValues;
  final List<NoteRelation> relations;

  AnnotateNoteParams({
    required this.noteId,
    required this.templateId,
    required this.propertyValues,
    this.relations = const [],
  });
}

/// Caso de uso para anotar uma nota com metadados semânticos
class AnnotateNote implements UseCase<SemanticAnnotation, AnnotateNoteParams> {
  final SemanticRepository repository;

  AnnotateNote(this.repository);

  @override
  Future<SemanticAnnotation> call(AnnotateNoteParams params) async {
    // Buscar template
    final template = await repository.getTemplate(params.templateId);
    
    if (template == null) {
      throw Exception('Template não encontrado: ${params.templateId}');
    }

    // Validar valores obrigatórios
    final validation = template.validateValues(params.propertyValues);
    
    if (!validation.isValid) {
      throw ValidationException(
        'Validação falhou: ${validation.errors.join(", ")}',
        validation,
      );
    }

    // Verificar se já existe anotação para esta nota
    final existingAnnotation = await repository.getAnnotationByNoteId(params.noteId);
    
    if (existingAnnotation != null) {
      // Atualizar anotação existente
      final updatedAnnotation = existingAnnotation.copyWith(
        templateId: params.templateId,
        classUri: template.mainClass.uri,
        propertyValues: params.propertyValues,
        relations: params.relations,
        updatedAt: DateTime.now(),
      );
      
      await repository.saveAnnotation(updatedAnnotation);
      
      // Atualizar triplas RDF
      await repository.removeTriplesForNote(params.noteId);
      for (final triple in updatedAnnotation.toTriples()) {
        await repository.addTriple(triple);
      }
      
      return updatedAnnotation;
    }

    // Criar nova anotação
    final annotation = SemanticAnnotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      noteId: params.noteId,
      templateId: params.templateId,
      classUri: template.mainClass.uri,
      propertyValues: params.propertyValues,
      relations: params.relations,
      createdAt: DateTime.now(),
    );

    // Salvar anotação
    final success = await repository.saveAnnotation(annotation);
    
    if (!success) {
      throw Exception('Falha ao salvar anotação');
    }

    // Salvar triplas RDF
    for (final triple in annotation.toTriples()) {
      await repository.addTriple(triple);
    }

    return annotation;
  }
}

/// Exceção de validação com detalhes
class ValidationException implements Exception {
  final String message;
  final ValidationResult validationResult;

  ValidationException(this.message, this.validationResult);

  @override
  String toString() => 'ValidationException: $message';
}
