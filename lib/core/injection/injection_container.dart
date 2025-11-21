import 'package:get_it/get_it.dart';

// Notes Feature
import '../../features/notes/data/datasources/note_local_data_source.dart';
import '../../features/notes/data/datasources/note_local_data_source_impl.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/notes/domain/usecases/read_markdown.dart';
import '../../features/notes/domain/usecases/generate_metadata.dart';
import '../../features/notes/domain/usecases/store_data.dart';
import '../../features/notes/domain/usecases/link_information.dart';
import '../../features/notes/domain/usecases/create_graph.dart';
import '../../features/notes/domain/usecases/create_template.dart';

// Semantic Feature
import '../../features/semantic/data/datasources/semantic_local_data_source.dart';
import '../../features/semantic/data/datasources/semantic_local_data_source_impl.dart';
import '../../features/semantic/data/repositories/semantic_repository_impl.dart';
import '../../features/semantic/domain/repositories/semantic_repository.dart';
import '../../features/semantic/domain/usecases/create_ontology.dart';
import '../../features/semantic/domain/usecases/add_ontology_class.dart';
import '../../features/semantic/domain/usecases/add_ontology_property.dart';
import '../../features/semantic/domain/usecases/create_semantic_template.dart';
import '../../features/semantic/domain/usecases/annotate_note.dart';
import '../../features/semantic/domain/usecases/get_semantic_templates.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ============================================
  // Notes Feature
  // ============================================
  
  // Use Cases
  sl.registerLazySingleton(() => ReadMarkdown(sl()));
  sl.registerLazySingleton(() => GenerateMetadata(sl()));
  sl.registerLazySingleton(() => StoreData(sl()));
  sl.registerLazySingleton(() => LinkInformation(sl()));
  sl.registerLazySingleton(() => CreateGraph(sl()));
  sl.registerLazySingleton(() => CreateTemplate(sl()));

  // Repository
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(sl()),
  );

  // Data Sources
  sl.registerLazySingleton<NoteLocalDataSource>(
    () => NoteLocalDataSourceImpl(),
  );

  // ============================================
  // Semantic Feature
  // ============================================
  
  // Use Cases
  sl.registerLazySingleton(() => CreateOntology(sl()));
  sl.registerLazySingleton(() => AddOntologyClass(sl()));
  sl.registerLazySingleton(() => AddOntologyProperty(sl()));
  sl.registerLazySingleton(() => CreateSemanticTemplate(sl()));
  sl.registerLazySingleton(() => AnnotateNote(sl()));
  sl.registerLazySingleton(() => GetSemanticTemplates(sl()));
  sl.registerLazySingleton(() => GetActiveTemplates(sl()));
  sl.registerLazySingleton(() => GetSemanticTemplate(sl()));

  // Repository
  sl.registerLazySingleton<SemanticRepository>(
    () => SemanticRepositoryImpl(sl()),
  );

  // Data Sources
  sl.registerLazySingleton<SemanticLocalDataSource>(
    () => SemanticLocalDataSourceImpl(),
  );
}
