// lib/core/injection/injection_container.dart

import 'package:get_it/get_it.dart';
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

final sl = GetIt.instance;

Future<void> init() async {
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
}
