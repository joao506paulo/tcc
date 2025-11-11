import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note.dart';
import '../providers/note_providers.dart';
import '../widgets/note_editor.dart';
import '../widgets/metadata_card.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorPage({Key? key, this.noteId}) : super(key: key);

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  String _content = '';
  Note? _currentNote;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _showMetadata = true;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    setState(() => _isLoading = true);
    
    final repository = ref.read(noteRepositoryProvider);
    final note = await repository.getNote(widget.noteId!);
    
    if (note != null) {
      setState(() {
        _currentNote = note;
        _content = note.content;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota não encontrada')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveNote() async {
    setState(() => _isLoading = true);

    final controller = ref.read(noteControllerProvider.notifier);
    
    try {
      if (_currentNote == null) {
        // Nova nota
        await controller.createNote(_content);
      } else {
        // Atualizar nota existente
        await controller.updateNote(_currentNote!, _content);
      }

      // Recarregar nota para obter metadados atualizados
      final noteState = ref.read(noteControllerProvider);
      noteState.whenData((note) {
        if (note != null) {
          setState(() {
            _currentNote = note;
            _hasChanges = false;
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota salva com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('Você tem alterações não salvas. Deseja descartá-las?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentNote == null ? 'Nova Nota' : 'Editar Nota'),
          actions: [
            IconButton(
              icon: Icon(_showMetadata ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() => _showMetadata = !_showMetadata);
              },
              tooltip: _showMetadata ? 'Ocultar Metadados' : 'Mostrar Metadados',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveNote,
              tooltip: 'Salvar',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  // Editor
                  Expanded(
                    flex: _showMetadata ? 2 : 1,
                    child: NoteEditor(
                      initialContent: _content,
                      onChanged: (content) {
                        setState(() {
                          _content = content;
                          _hasChanges = true;
                        });
                      },
                    ),
                  ),
                  
                  // Painel de metadados
                  if (_showMetadata && _currentNote != null)
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: MetadataCard(
                          note: _currentNote!,
                          onRefresh: _saveNote,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
