import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/graph.dart';
import '../../domain/usecases/read_markdown.dart';
import '../../domain/usecases/generate_metadata.dart';
import '../../domain/usecases/store_data.dart';
import '../../domain/usecases/link_information.dart';
import '../../domain/usecases/create_graph.dart';
import '../../domain/usecases/create_template.dart';
import '../../domain/repositories/note_repository.dart';

final sl = GetIt.instance;

// Use Cases Providers
final readMarkdownProvider = Provider((ref) => sl<ReadMarkdown>());
final generateMetadataProvider = Provider((ref) => sl<GenerateMetadata>());
final storeDataProvider = Provider((ref) => sl<StoreData>());
final linkInformationProvider = Provider((ref) => sl<LinkInformation>());
final createGraphProvider = Provider((ref) => sl<CreateGraph>());
final createTemplateProvider = Provider((ref) => sl<CreateTemplate>());
final noteRepositoryProvider = Provider((ref) => sl<NoteRepository>());

// State Providers
final currentNoteProvider = StateProvider<Note?>((ref) => null);
final allNotesProvider = StateProvider<List<Note>>((ref) => []);
final currentGraphProvider = StateProvider<Graph?>((ref) => null);
final selectedTemplateProvider = StateProvider<String?>((ref) => null);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Notes List Provider (AsyncNotifier)
final notesListProvider = FutureProvider<List<Note>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.getAllNotes();
});

// Available Templates Provider
final availableTemplatesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.getAvailableTemplates();
});

// Note Controller Provider
class NoteController extends StateNotifier<AsyncValue<Note?>> {
  final ReadMarkdown readMarkdown;
  final GenerateMetadata generateMetadata;
  final StoreData storeData;
  final NoteRepository repository;

  NoteController({
    required this.readMarkdown,
    required this.generateMetadata,
    required this.storeData,
    required this.repository,
  }) : super(const AsyncValue.data(null));

  Future<void> loadNote(String id) async {
    state = const AsyncValue.loading();
    try {
      final note = await repository.getNote(id);
      state = AsyncValue.data(note);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createNote(String content) async {
    state = const AsyncValue.loading();
    try {
      var note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        metadata: {},
      );

      // Gerar metadados
      note = await generateMetadata(note);

      // Salvar
      await storeData(note);

      state = AsyncValue.data(note);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateNote(Note note, String newContent) async {
    state = const AsyncValue.loading();
    try {
      var updatedNote = Note(
        id: note.id,
        content: newContent,
        metadata: note.metadata,
      );

      // Regenerar metadados
      updatedNote = await generateMetadata(updatedNote);

      // Atualizar
      await storeData(updatedNote);

      state = AsyncValue.data(updatedNote);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNote(String id) async {
    state = const AsyncValue.loading();
    try {
      await repository.deleteNote(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final noteControllerProvider =
    StateNotifierProvider<NoteController, AsyncValue<Note?>>((ref) {
  return NoteController(
    readMarkdown: ref.watch(readMarkdownProvider),
    generateMetadata: ref.watch(generateMetadataProvider),
    storeData: ref.watch(storeDataProvider),
    repository: ref.watch(noteRepositoryProvider),
  );
});

// Graph Controller Provider
class GraphController extends StateNotifier<AsyncValue<Graph?>> {
  final CreateGraph createGraph;
  final LinkInformation linkInformation;
  final NoteRepository repository;

  GraphController({
    required this.createGraph,
    required this.linkInformation,
    required this.repository,
  }) : super(const AsyncValue.data(null));

  Future<void> generateGraph({
    bool includeTagNodes = true,
    bool includeLinkNodes = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final notes = await repository.getAllNotes();
      
      final graph = await createGraph(
        CreateGraphParams(
          notes: notes,
          includeTagNodes: includeTagNodes,
          includeLinkNodes: includeLinkNodes,
        ),
      );

      state = AsyncValue.data(graph);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> linkNotesGraph(List<Note> notes) async {
    state = const AsyncValue.loading();
    try {
      final graph = await linkInformation(notes);
      state = AsyncValue.data(graph);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final graphControllerProvider =
    StateNotifierProvider<GraphController, AsyncValue<Graph?>>((ref) {
  return GraphController(
    createGraph: ref.watch(createGraphProvider),
    linkInformation: ref.watch(linkInformationProvider),
    repository: ref.watch(noteRepositoryProvider),
  );
});
