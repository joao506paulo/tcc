import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/graph.dart';
import '../providers/note_providers.dart';
import '../widgets/graph_widget.dart';
import 'note_editor_page.dart';

class GraphViewPage extends ConsumerStatefulWidget {
  const GraphViewPage({Key? key}) : super(key: key);

  @override
  ConsumerState<GraphViewPage> createState() => _GraphViewPageState();
}

class _GraphViewPageState extends ConsumerState<GraphViewPage> {
  bool _includeTagNodes = true;
  bool _includeLinkNodes = true;

  @override
  void initState() {
    super.initState();
    _generateGraph();
  }

  Future<void> _generateGraph() async {
    final controller = ref.read(graphControllerProvider.notifier);
    await controller.generateGraph(
      includeTagNodes: _includeTagNodes,
      includeLinkNodes: _includeLinkNodes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final graphState = ref.watch(graphControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafo de Conhecimento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateGraph,
            tooltip: 'Atualizar Grafo',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: graphState.when(
        data: (graph) {
          if (graph == null) {
            return const Center(
              child: Text('Gerando grafo...'),
            );
          }
          return GraphWidget(
            graph: graph,
            onNodeTap: (node) => _onNodeTap(context, node),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Gerando grafo...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao gerar grafo: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generateGraph,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNodeTap(BuildContext context, GraphNode node) {
    if (node.type == 'note') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteEditorPage(noteId: node.id),
        ),
      ).then((_) {
        // Atualizar grafo após retornar
        _generateGraph();
      });
    } else if (node.type == 'tag') {
      _showTagInfo(context, node);
    }
  }

  void _showTagInfo(BuildContext context, GraphNode node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.label, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Tag: ${node.label}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${node.id}'),
            const SizedBox(height: 8),
            Text('Tipo: ${node.type}'),
            if (node.properties.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Propriedades:'),
              ...node.properties.entries.map((e) => 
                Text('  ${e.key}: ${e.value}')
              ),
            ],
          ],
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

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações do Grafo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Mostrar Tags'),
              subtitle: const Text('Incluir nós de tags no grafo'),
              value: _includeTagNodes,
              onChanged: (value) {
                setState(() => _includeTagNodes = value);
              },
            ),
            SwitchListTile(
              title: const Text('Mostrar Links'),
              subtitle: const Text('Incluir conexões entre notas'),
              value: _includeLinkNodes,
              onChanged: (value) {
                setState(() => _includeLinkNodes = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateGraph();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
