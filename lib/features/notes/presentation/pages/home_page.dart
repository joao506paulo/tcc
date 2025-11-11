import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note.dart';
import '../providers/note_providers.dart';
import 'note_editor_page.dart';
import 'graph_view_page.dart';
import 'templates_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Notas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GraphViewPage(),
                ),
              );
            },
            tooltip: 'Ver Grafo',
          ),
          IconButton(
            icon: const Icon(Icons.temple_buddhist),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TemplatesPage(),
                ),
              );
            },
            tooltip: 'Templates',
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) => _buildNotesList(context, ref, notes),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(notesListProvider),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteEditorPage(),
            ),
          ).then((_) {
            // Atualizar lista após retornar
            ref.refresh(notesListProvider);
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Nova Nota',
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, WidgetRef ref, List<Note> notes) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma nota ainda',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + para criar sua primeira nota',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(notesListProvider);
      },
      child: ListView.builder(
        itemCount: notes.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteCard(context, ref, note);
        },
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, WidgetRef ref, Note note) {
    final title = note.metadata['title'] as String? ?? 'Sem título';
    final tags = note.metadata['tags'] as List? ?? [];
    final wordCount = note.metadata['word_count'] ?? 0;
    final createdAt = note.metadata['created_at'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorPage(noteId: note.id),
            ),
          ).then((_) {
            ref.refresh(notesListProvider);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Deletar'),
                          ],
                        ),
                        onTap: () async {
                          final controller = ref.read(noteControllerProvider.notifier);
                          await controller.deleteNote(note.id);
                          ref.refresh(notesListProvider);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Preview do conteúdo
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              
              const SizedBox(height: 12),
              
              // Tags
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: tags.take(3).map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      backgroundColor: Colors.blue[100],
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 8),
              
              // Informações adicionais
              Row(
                children: [
                  Icon(Icons.text_fields, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$wordCount palavras',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
