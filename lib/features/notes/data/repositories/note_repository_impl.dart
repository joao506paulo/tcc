import 'dart:io';
import '../../domain/entities/note.dart';
import '../../domain/entities/graph.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/create_graph.dart';
import '../../domain/usecases/create_template.dart';
import '../datasources/note_local_data_source.dart';
import '../models/note_model.dart';
import '../models/graph_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;

  NoteRepositoryImpl(this.localDataSource);

  @override
  Future<Note> readMarkdown(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();

      // Extrair metadados do frontmatter YAML
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
    } catch (e) {
      throw Exception('Failed to read markdown file: $e');
    }
  }

  @override
  Future<Note> generateMetadata(Note note) async {
    try {
      final metadata = <String, dynamic>{...note.metadata};
      final content = note.content;

      // Extrair título do primeiro H1
      final titleRegex = RegExp(r'^#\s+(.+)$', multiLine: true);
      final titleMatch = titleRegex.firstMatch(content);
      if (titleMatch != null) {
        metadata['title'] = titleMatch.group(1)?.trim() ?? '';
      }

      // Extrair tags (#tag)
      final tagRegex = RegExp(r'#(\w+)');
      final tagMatches = tagRegex.allMatches(content);
      final tags = tagMatches
          .map((match) => match.group(1)!)
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList();
      metadata['tags'] = tags;

      // Extrair links internos ([[link]])
      final linkRegex = RegExp(r'\[\[([^\]]+)\]\]');
      final linkMatches = linkRegex.allMatches(content);
      final links = linkMatches
          .map((match) => match.group(1)!)
          .where((link) => link.isNotEmpty)
          .toList();
      metadata['links'] = links;

      // Contar palavras
      final wordCount = content
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
      metadata['word_count'] = wordCount;

      // Adicionar timestamp
      metadata['created_at'] = DateTime.now().toIso8601String();

      return Note(
        id: note.id,
        content: note.content,
        metadata: metadata,
      );
    } catch (e) {
      throw Exception('Failed to generate metadata: $e');
    }
  }

  @override
  Future<bool> storeNote(Note note) async {
    try {
      final noteModel = NoteModel.fromEntity(note);
      return await localDataSource.saveNote(noteModel);
    } catch (e) {
      print('Error storing note: $e');
      return false;
    }
  }

  @override
  Future<Note?> getNote(String id) async {
    try {
      final noteModel = await localDataSource.getNote(id);
      return noteModel?.toEntity();
    } catch (e) {
      print('Error getting note: $e');
      return null;
    }
  }

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      final noteModels = await localDataSource.getAllNotes();
      return noteModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting all notes: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteNote(String id) async {
    try {
      return await localDataSource.deleteNote(id);
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  @override
  Future<Graph> linkNotes(List<Note> notes) async {
    try {
      final nodes = <GraphNode>[];
      final edges = <GraphEdge>[];

      // Criar nós para cada nota
      for (final note in notes) {
        final title = note.metadata['title'] as String? ?? 'Sem título';
        nodes.add(GraphNode(
          id: note.id,
          label: title,
          type: 'note',
          properties: {'content_length': note.content.length},
        ));
      }

      // Criar arestas baseadas nos links
      int edgeCounter = 0;
      for (final note in notes) {
        final links = note.metadata['links'] as List? ?? [];
        
        for (final link in links) {
          // Encontrar a nota alvo pelo título ou ID
          final targetNote = notes.firstWhere(
            (n) => n.metadata['title'] == link || n.id == link,
            orElse: () => Note(id: '', content: '', metadata: {}),
          );

          if (targetNote.id.isNotEmpty) {
            edges.add(GraphEdge(
              id: 'edge-${edgeCounter++}',
              sourceId: note.id,
              targetId: targetNote.id,
              relationship: 'references',
              properties: {'link_text': link},
            ));
          }
        }
      }

      return Graph(
        id: 'graph-${DateTime.now().millisecondsSinceEpoch}',
        nodes: nodes,
        edges: edges,
        metadata: {
          'created_at': DateTime.now().toIso8601String(),
          'node_count': nodes.length,
          'edge_count': edges.length,
        },
      );
    } catch (e) {
      throw Exception('Failed to link notes: $e');
    }
  }

  @override
  Future<Graph> createSemanticGraph(CreateGraphParams params) async {
    try {
      final nodes = <GraphNode>[];
      final edges = <GraphEdge>[];
      int edgeCounter = 0;

      // Adicionar nós de notas
      for (final note in params.notes) {
        final title = note.metadata['title'] as String? ?? 'Sem título';
        nodes.add(GraphNode(
          id: note.id,
          label: title,
          type: 'note',
          properties: {
            'content_length': note.content.length,
            'word_count': note.metadata['word_count'] ?? 0,
          },
        ));
      }

      // Adicionar nós de tags se habilitado
      if (params.includeTagNodes) {
        final allTags = <String>{};
        for (final note in params.notes) {
          final tags = note.metadata['tags'] as List? ?? [];
          allTags.addAll(tags.cast<String>());
        }

        for (final tag in allTags) {
          nodes.add(GraphNode(
            id: 'tag-$tag',
            label: tag,
            type: 'tag',
          ));
        }

        // Criar arestas nota -> tag
        for (final note in params.notes) {
          final tags = note.metadata['tags'] as List? ?? [];
          for (final tag in tags) {
            edges.add(GraphEdge(
              id: 'edge-${edgeCounter++}',
              sourceId: note.id,
              targetId: 'tag-$tag',
              relationship: 'has_tag',
            ));
          }
        }
      }

      // Adicionar arestas de links entre notas
      if (params.includeLinkNodes) {
        for (final note in params.notes) {
          final links = note.metadata['links'] as List? ?? [];
          
          for (final link in links) {
            final targetNote = params.notes.firstWhere(
              (n) => n.metadata['title'] == link || n.id == link,
              orElse: () => Note(id: '', content: '', metadata: {}),
            );

            if (targetNote.id.isNotEmpty) {
              edges.add(GraphEdge(
                id: 'edge-${edgeCounter++}',
                sourceId: note.id,
                targetId: targetNote.id,
                relationship: 'links_to',
              ));
            }
          }
        }
      }

      final graph = Graph(
        id: 'semantic-graph-${DateTime.now().millisecondsSinceEpoch}',
        nodes: nodes,
        edges: edges,
        metadata: {
          'created_at': DateTime.now().toIso8601String(),
          'node_count': nodes.length,
          'edge_count': edges.length,
        },
      );

      // Salvar o grafo
      final graphModel = GraphModel.fromEntity(graph);
      await localDataSource.saveGraph(graphModel);

      return graph;
    } catch (e) {
      throw Exception('Failed to create semantic graph: $e');
    }
  }

  @override
  Future<Note> createFromTemplate(TemplateParams params) async {
    try {
      String content = '';
      final metadata = <String, dynamic>{
        'template': params.templateType,
        'is_template': false,
      };

      switch (params.templateType) {
        case 'daily-note':
          content = _createDailyNoteTemplate(params.variables);
          metadata['title'] = 'Daily Note - ${params.variables['date']}';
          metadata['date'] = params.variables['date'];
          break;

        case 'project':
          content = _createProjectTemplate(params.variables);
          metadata['title'] = params.variables['project_name'];
          metadata['type'] = 'project';
          metadata['start_date'] = params.variables['start_date'];
          break;

        case 'meeting':
          content = _createMeetingTemplate(params.variables);
          metadata['title'] = params.variables['meeting_title'];
          metadata['date'] = params.variables['date'];
          metadata['participants'] = params.variables['participants'];
          break;

        default:
          throw Exception('Unknown template type: ${params.templateType}');
      }

      return Note(
        id: 'template-${params.templateType}-${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        metadata: metadata,
      );
    } catch (e) {
      throw Exception('Failed to create from template: $e');
    }
  }

  String _createDailyNoteTemplate(Map<String, String> vars) {
    final date = vars['date'] ?? '';
    final dayOfWeek = vars['day_of_week'] ?? '';

    return '''---
title: Daily Note - $date
date: $date
day_of_week: $dayOfWeek
template: daily-note
---

# $date - $dayOfWeek

## Tarefas
- [ ] 

## Notas do Dia


## Reflexões


## Links
- [[${_getPreviousDate(date)}]]
- [[${_getNextDate(date)}]]
''';
  }

  String _createProjectTemplate(Map<String, String> vars) {
    final projectName = vars['project_name'] ?? 'Novo Projeto';
    final startDate = vars['start_date'] ?? '';

    return '''---
title: $projectName
type: project
start_date: $startDate
template: project
---

# $projectName

## Objetivo


## Tarefas
- [ ] 

## Recursos


## Timeline

''';
  }

  String _createMeetingTemplate(Map<String, String> vars) {
    final meetingTitle = vars['meeting_title'] ?? 'Reunião';
    final date = vars['date'] ?? '';
    final participants = vars['participants'] ?? '';

    return '''---
title: $meetingTitle
date: $date
participants: $participants
template: meeting
---

# $meetingTitle

**Data:** $date
**Participantes:** $participants

## Pauta


## Discussão


## Ações
- [ ] 

## Próximos Passos

''';
  }

  String _getPreviousDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final previousDate = date.subtract(const Duration(days: 1));
      return previousDate.toIso8601String().split('T')[0];
    } catch (e) {
      return dateStr;
    }
  }

  String _getNextDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final nextDate = date.add(const Duration(days: 1));
      return nextDate.toIso8601String().split('T')[0];
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Future<List<String>> getAvailableTemplates() async {
    return [
      'daily-note',
      'project',
      'meeting',
    ];
  }
}
