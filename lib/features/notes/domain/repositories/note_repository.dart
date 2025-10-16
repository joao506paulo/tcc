import '../entities/note.dart';

abstract class NoteRepository {
  Future<Note> readMarkdown(String path);
}
