import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note.dart';
import '../providers/note_providers.dart';
import 'note_editor_page.dart';
import 'graph_view_page.dart';
import 'templates_page.dart';
import '../../../semantic/presentation/pages/semantic_templates_page.dart';
import '../../../semantic/presentation/pages/ontology_list_page.dart';
import '../../../semantic/presentation/providers/semantic_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Notas'),
        actions: [
          // Menu de Web Semântica
          PopupMenuButton<String>(
            icon: const Icon(Icons.schema),
            tooltip: 'Web Semântica',
            onSelected: (value) {
              switch (value) {
                case 'ontologies':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OntologyListPage()),
                  );
                  break;
                case 'semantic_templates':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SemanticTemplatesPage()),
                  );
                  break;
                case 'sparql':
                  _showSparqlDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ontologies',
                child: Row(
                  children: [
                    Icon(Icons.schema, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Ontologias'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'semantic_templates',
                child: Row(
                  children: [
                    Icon(Icons.article, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Templates Semânticos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sparql',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Consulta SPARQL'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_tree),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GraphViewPage()),
              );
            },
            tooltip: 'Ver Grafo',
          ),
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TemplatesPage()),
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
            MaterialPageRoute(builder: (context) => const NoteEditorPage()),
          ).then((_) => ref.refresh(notesListProvider));
        },
        tooltip: 'Nova Nota',
        child: const Icon(Icons.add),
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
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OntologyListPage()),
                );
              },
              icon: const Icon(Icons.schema),
              label: const Text('Configurar Web Semântica'),
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
          return _NoteCard(note: note);
        },
      ),
    );
  }

  void _showSparqlDialog(BuildContext context, WidgetRef ref) {
    final queryController = TextEditingController(
      text: 'SELECT ?s ?p ?o WHERE { ?s ?p ?o }',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consulta SPARQL'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Digite uma consulta SPARQL simplificada:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: queryController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'SELECT ?s ?p ?o WHERE { ?s ?p ?o }',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Exemplos:\n'
                '• SELECT ?s ?p ?o WHERE { ?s ?p ?o }\n'
                '• SELECT ?s WHERE { ?s rdf:type :Aula }',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _executeSparql(context, ref, queryController.text);
            },
            child: const Text('Executar'),
          ),
        ],
      ),
    );
  }

  void _executeSparql(BuildContext context, WidgetRef ref, String query) async {
    final repository = ref.read(semanticRepositoryProvider);
    
    try {
      final results = await repository.executeSparqlSelect(query);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Resultados (${results.length})'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: results.isEmpty
                  ? const Center(child: Text('Nenhum resultado encontrado'))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: result.entries.map((e) => Text(
                                '${e.key}: ${e.value}',
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              )).toList(),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = note.metadata['title'] as String? ?? 'Sem título';
    final tags = note.metadata['tags'] as List? ?? [];
    final wordCount = note.metadata['word_count'] ?? 0;
    final createdAt = note.metadata['created_at'] as String?;

    // Verificar se tem anotação semântica
    final annotationAsync = ref.watch(annotationByNoteProvider(note.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorPage(noteId: note.id),
            ),
          ).then((_) => ref.refresh(notesListProvider));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Indicador de anotação semântica
                  annotationAsync.when(
                    data: (annotation) {
                      if (annotation != null) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: 'Tipo: ${annotation.classUri.split('#').last}',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(Icons.label, size: 16, color: Colors.purple[700]),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
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
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: tags.take(3).map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      backgroundColor: Colors.blue[100],
                      labelStyle: const TextStyle(fontSize: 12, color: Colors.blue),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
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
