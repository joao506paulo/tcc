import 'dart:io';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  @override
  Future<Note> readMarkdown(String path) async {
    final file = File(path);
    final content = await file.readAsString();

    final metadata = <String, dynamic>{};
    final regex = RegExp(r'^---([\s\S]*?)---', multiLine: true);
    final match = regex.firstMatch(content);
    if (match != null) {
      final yamlBlock = match.group(1) ?? '';
      final lines = yamlBlock.split('\n');
      for (var line in lines) {
        final parts = line.split(':');
        if (parts.length == 2) {
          metadata[parts[0].trim()] = parts[1].trim();
        }
      }
    }

    return Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      metadata: metadata,
    );
  }
}
