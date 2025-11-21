import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note.dart';
import '../providers/note_providers.dart';
import '../widgets/note_editor.dart';
import '../widgets/metadata_card.dart';
import '../../../semantic/presentation/widgets/note_annotation_widget.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorPage({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  String _content = '';
  Note? _currentNote;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _showMetadata = true;
  bool _showSemanticPanel = false;

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
        await controller.createNote(_content);
      } else {
        await controller.updateNote(_currentNote!, _content);
      }

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
            // Botão de anotação semântica
            if (_currentNote != null)
              IconButton(
                icon: Icon(
                  _showSemanticPanel ? Icons.label : Icons.label_outline,
                  color: _showSemanticPanel ? Colors.purple : null,
                ),
                onPressed: () {
                  setState(() => _showSemanticPanel = !_showSemanticPanel);
                },
                tooltip: 'Anotação Semântica',
              ),
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
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Row(
      children: [
        // Editor principal
        Expanded(
          flex: 2,
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
        
        // Painel lateral
        if (_showMetadata || _showSemanticPanel)
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Anotação semântica
                  if (_showSemanticPanel && _currentNote != null)
                    NoteAnnotationWidget(
                      noteId: _currentNote!.id,
                      onAnnotationSaved: () {
                        // Recarregar nota para atualizar metadados
                        _loadNote();
                      },
                    ),
                  
                  // Metadados tradicionais
                  if (_showMetadata && _currentNote != null)
                    MetadataCard(
                      note: _currentNote!,
                      onRefresh: _saveNote,
                    ),
                  
                  // Dica para salvar primeiro
                  if (_currentNote == null)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Salve a nota primeiro para adicionar metadados e anotações semânticas',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
