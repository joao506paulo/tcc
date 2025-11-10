import '../models/note_model.dart';
import '../models/graph_model.dart';

abstract class NoteLocalDataSource {
  /// Salva uma nota no storage local
  Future<bool> saveNote(NoteModel note);
  
  /// Recupera uma nota por ID
  Future<NoteModel?> getNote(String id);
  
  /// Recupera todas as notas
  Future<List<NoteModel>> getAllNotes();
  
  /// Deleta uma nota por ID
  Future<bool> deleteNote(String id);
  
  /// Atualiza uma nota existente
  Future<bool> updateNote(NoteModel note);
  
  /// Salva um grafo
  Future<bool> saveGraph(GraphModel graph);
  
  /// Recupera um grafo por ID
  Future<GraphModel?> getGraph(String id);
  
  /// Recupera todos os grafos
  Future<List<GraphModel>> getAllGraphs();
  
  /// Verifica se uma nota existe
  Future<bool> noteExists(String id);
  
  /// Busca notas por tag
  Future<List<NoteModel>> getNotesByTag(String tag);
  
  /// Busca notas por título
  Future<List<NoteModel>> searchNotesByTitle(String query);
}
