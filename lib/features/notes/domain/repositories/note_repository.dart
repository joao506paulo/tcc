import '../entities/note.dart';
import '../entities/graph.dart';
import '../usecases/create_graph.dart';
import '../usecases/create_template.dart';

abstract class NoteRepository {
  // Leitura de arquivo markdown
  Future<Note> readMarkdown(String path);
  
  // Geração de metadados
  Future<Note> generateMetadata(Note note);
  
  // Armazenamento de dados
  Future<bool> storeNote(Note note);
  Future<Note?> getNote(String id);
  Future<List<Note>> getAllNotes();
  Future<bool> deleteNote(String id);
  
  // Ligação de informações
  Future<Graph> linkNotes(List<Note> notes);
  
  // Criação de grafos semânticos
  Future<Graph> createSemanticGraph(CreateGraphParams params);
  
  // Criação de templates
  Future<Note> createFromTemplate(TemplateParams params);
  Future<List<String>> getAvailableTemplates();
}
