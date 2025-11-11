import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

class NoteEditor extends ConsumerStatefulWidget {
  final String initialContent;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const NoteEditor({
    Key? key,
    this.initialContent = '',
    this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  late TextEditingController _controller;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _togglePreviewMode() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
    });
  }

  void _insertMarkdown(String prefix, [String suffix = '']) {
    final selection = _controller.selection;
    final text = _controller.text;
    final selectedText = text.substring(selection.start, selection.end);

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        _buildToolbar(),
        const Divider(height: 1),
        
        // Editor/Preview
        Expanded(
          child: _isPreviewMode
              ? _buildPreview()
              : _buildEditor(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[100],
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.preview),
            onPressed: _togglePreviewMode,
            tooltip: _isPreviewMode ? 'Editar' : 'Visualizar',
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.format_bold),
            onPressed: () => _insertMarkdown('**', '**'),
            tooltip: 'Negrito',
          ),
          IconButton(
            icon: const Icon(Icons.format_italic),
            onPressed: () => _insertMarkdown('*', '*'),
            tooltip: 'Itálico',
          ),
          IconButton(
            icon: const Icon(Icons.title),
            onPressed: () => _insertMarkdown('# '),
            tooltip: 'Título',
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () => _insertMarkdown('[[', ']]'),
            tooltip: 'Link Interno',
          ),
          IconButton(
            icon: const Icon(Icons.label),
            onPressed: () => _insertMarkdown('#'),
            tooltip: 'Tag',
          ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => _insertMarkdown('`', '`'),
            tooltip: 'Código Inline',
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            onPressed: () => _insertMarkdown('- '),
            tooltip: 'Lista',
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        readOnly: widget.readOnly,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Digite seu texto em Markdown...',
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final htmlContent = md.markdownToHtml(
      _controller.text,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // Aqui você pode usar um package como flutter_html
            // para renderizar o HTML de forma mais rica
            SelectableText(
              _controller.text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
