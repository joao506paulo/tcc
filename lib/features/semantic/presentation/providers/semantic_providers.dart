import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/injection_container.dart' as di;
import '../../domain/entities/ontology.dart';
import '../../domain/entities/ontology.dart';
import '../../domain/entities/ontology_class.dart';
import '../../domain/entities/ontology_property.dart';
import '../../domain/entities/semantic_template.dart';
import '../../domain/entities/semantic_annotation.dart';
import '../../domain/repositories/semantic_repository.dart';
import '../../domain/usecases/create_ontology.dart';
import '../../domain/usecases/add_ontology_class.dart';
import '../../domain/usecases/add_ontology_property.dart';
import '../../domain/usecases/create_semantic_template.dart';
import '../../domain/usecases/annotate_note.dart';
import '../../domain/usecases/get_semantic_templates.dart';

// ============================================
// Use Case Providers
// ============================================

final createOntologyProvider = Provider((ref) => di.sl<CreateOntology>());
final addOntologyClassProvider = Provider((ref) => di.sl<AddOntologyClass>());
final addOntologyPropertyProvider = Provider((ref) => di.sl<AddOntologyProperty>());
final createSemanticTemplateProvider = Provider((ref) => di.sl<CreateSemanticTemplate>());
final annotateNoteProvider = Provider((ref) => di.sl<AnnotateNote>());
final getSemanticTemplatesProvider = Provider((ref) => di.sl<GetSemanticTemplates>());
final getActiveTemplatesProvider = Provider((ref) => di.sl<GetActiveTemplates>());
final semanticRepositoryProvider = Provider((ref) => di.sl<SemanticRepository>());

// ============================================
// State Providers
// ============================================

final selectedOntologyProvider = StateProvider<Ontology?>((ref) => null);
final selectedTemplateProvider = StateProvider<SemanticTemplate?>((ref) => null);
final selectedClassProvider = StateProvider<OntologyClass?>((ref) => null);

// ============================================
// Async Providers
// ============================================

final ontologiesListProvider = FutureProvider<List<Ontology>>((ref) async {
  final repository = ref.watch(semanticRepositoryProvider);
  return await repository.getAllOntologies();
});

final semanticTemplatesListProvider = FutureProvider<List<SemanticTemplate>>((ref) async {
  final repository = ref.watch(semanticRepositoryProvider);
  return await repository.getActiveTemplates();
});

final allSemanticTemplatesProvider = FutureProvider<List<SemanticTemplate>>((ref) async {
  final repository = ref.watch(semanticRepositoryProvider);
  return await repository.getAllTemplates();
});

// ============================================
// Ontology Controller
// ============================================

class OntologyController extends StateNotifier<AsyncValue<Ontology?>> {
  final CreateOntology createOntology;
  final AddOntologyClass addOntologyClass;
  final AddOntologyProperty addOntologyProperty;
  final SemanticRepository repository;

  OntologyController({
    required this.createOntology,
    required this.addOntologyClass,
    required this.addOntologyProperty,
    required this.repository,
  }) : super(const AsyncValue.data(null));

  Future<Ontology> create(String name, String? description) async {
    state = const AsyncValue.loading();
    try {
      final ontology = await createOntology(CreateOntologyParams(
        name: name,
        description: description,
      ));
      state = AsyncValue.data(ontology);
      return ontology;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> load(String id) async {
    state = const AsyncValue.loading();
    try {
      final ontology = await repository.getOntology(id);
      state = AsyncValue.data(ontology);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<OntologyClass> addClass({
    required String ontologyId,
    required String label,
    String? description,
    String? parentClassUri,
  }) async {
    try {
      final ontologyClass = await addOntologyClass(AddOntologyClassParams(
        ontologyId: ontologyId,
        label: label,
        description: description,
        parentClassUri: parentClassUri,
      ));
      
      // Recarregar ontologia
      await load(ontologyId);
      return ontologyClass;
    } catch (e) {
      rethrow;
    }
  }

  Future<OntologyProperty> addProperty({
    required String ontologyId,
    required String label,
    String? description,
    required PropertyType type,
    required String domainClassUri,
    required String rangeUri,
    bool isRequired = false,
    bool isFunctional = false,
  }) async {
    try {
      final property = await addOntologyProperty(AddOntologyPropertyParams(
        ontologyId: ontologyId,
        label: label,
        description: description,
        type: type,
        domainClassUri: domainClassUri,
        rangeUri: rangeUri,
        isRequired: isRequired,
        isFunctional: isFunctional,
      ));
      
      await load(ontologyId);
      return property;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final result = await repository.deleteOntology(id);
      if (result) {
        state = const AsyncValue.data(null);
      }
      return result;
    } catch (e) {
      return false;
    }
  }
}

final ontologyControllerProvider =
    StateNotifierProvider<OntologyController, AsyncValue<Ontology?>>((ref) {
  return OntologyController(
    createOntology: ref.watch(createOntologyProvider),
    addOntologyClass: ref.watch(addOntologyClassProvider),
    addOntologyProperty: ref.watch(addOntologyPropertyProvider),
    repository: ref.watch(semanticRepositoryProvider),
  );
});

// ============================================
// Template Controller
// ============================================

class SemanticTemplateController extends StateNotifier<AsyncValue<SemanticTemplate?>> {
  final CreateSemanticTemplate createTemplate;
  final SemanticRepository repository;

  SemanticTemplateController({
    required this.createTemplate,
    required this.repository,
  }) : super(const AsyncValue.data(null));

  Future<SemanticTemplate> create({
    required String ontologyId,
    required String classUri,
    required String name,
    String? description,
    String? iconName,
    String? colorHex,
  }) async {
    state = const AsyncValue.loading();
    try {
      final template = await createTemplate(CreateSemanticTemplateParams(
        ontologyId: ontologyId,
        classUri: classUri,
        name: name,
        description: description,
        iconName: iconName,
        colorHex: colorHex,
      ));
      state = AsyncValue.data(template);
      return template;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> load(String id) async {
    state = const AsyncValue.loading();
    try {
      final template = await repository.getTemplate(id);
      state = AsyncValue.data(template);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> delete(String id) async {
    try {
      final result = await repository.deleteTemplate(id);
      if (result) {
        state = const AsyncValue.data(null);
      }
      return result;
    } catch (e) {
      return false;
    }
  }
}

final semanticTemplateControllerProvider =
    StateNotifierProvider<SemanticTemplateController, AsyncValue<SemanticTemplate?>>((ref) {
  return SemanticTemplateController(
    createTemplate: ref.watch(createSemanticTemplateProvider),
    repository: ref.watch(semanticRepositoryProvider),
  );
});

// ============================================
// Annotation Controller
// ============================================

class AnnotationController extends StateNotifier<AsyncValue<SemanticAnnotation?>> {
  final AnnotateNote annotateNote;
  final SemanticRepository repository;

  AnnotationController({
    required this.annotateNote,
    required this.repository,
  }) : super(const AsyncValue.data(null));

  Future<SemanticAnnotation> annotate({
    required String noteId,
    required String templateId,
    required Map<String, dynamic> propertyValues,
    List<NoteRelation> relations = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final annotation = await annotateNote(AnnotateNoteParams(
        noteId: noteId,
        templateId: templateId,
        propertyValues: propertyValues,
        relations: relations,
      ));
      state = AsyncValue.data(annotation);
      return annotation;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> loadByNoteId(String noteId) async {
    state = const AsyncValue.loading();
    try {
      final annotation = await repository.getAnnotationByNoteId(noteId);
      state = AsyncValue.data(annotation);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> delete(String noteId) async {
    try {
      final result = await repository.deleteAnnotationByNoteId(noteId);
      if (result) {
        state = const AsyncValue.data(null);
      }
      return result;
    } catch (e) {
      return false;
    }
  }
}

final annotationControllerProvider =
    StateNotifierProvider<AnnotationController, AsyncValue<SemanticAnnotation?>>((ref) {
  return AnnotationController(
    annotateNote: ref.watch(annotateNoteProvider),
    repository: ref.watch(semanticRepositoryProvider),
  );
});

// ============================================
// Annotation by Note Provider
// ============================================

final annotationByNoteProvider = FutureProvider.family<SemanticAnnotation?, String>((ref, noteId) async {
  final repository = ref.watch(semanticRepositoryProvider);
  return await repository.getAnnotationByNoteId(noteId);
});
