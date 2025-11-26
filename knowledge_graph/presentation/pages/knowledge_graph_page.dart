import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/knowledge_node.dart';
import '../../domain/repositories/knowledge_graph_repository.dart';
import '../providers/knowledge_graph_providers.dart';
import '../widgets/knowledge_graph_widget.dart';
import '../../../notes/presentation/pages/note_editor_page.dart';

class KnowledgeGraphPage extends ConsumerStatefulWidget {
  const KnowledgeGraphPage({super.key});

  @override
  ConsumerState<KnowledgeGraphPage> createState() => _KnowledgeGraphPageState();
}

class _KnowledgeGraphPageState extends ConsumerState<KnowledgeGraphPage> {
  bool _showInferred = true;
  bool _showTags = true;
  bool _showWikiLinks = true;
  bool _showLabels = true;
  String? _selectedNodeId;
  KnowledgeNode? _selectedNode;
  String? _classFilter;

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  Future<void> _loadGraph() async {
    final controller = ref.read(knowledgeGraphControllerProvider.notifier);
    await controller.generateGraph(
      includeInferred: _showInferred,
      includeTags: _showTags,
      includeWikiLinks: _showWikiLinks,
      filterByClasses: _classFilter != null ? [_classFilter!] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final graphState = ref.watch(knowledgeGraphControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafo de Conhecimento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.account_tree),
            onPressed: _showHierarchyDialog,
            tooltip: 'Hierarquia de Classes',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGraph,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: Row(
        children: [
          // Grafo principal
          Expanded(
            flex: 3,
            child: graphState.when(
              data: (graph) {
                if (graph == null) {
                  return const Center(child: Text('Gerando grafo...'));
                }
                return KnowledgeGraphWidget(
                  graph: graph,
                  showInferred: _showInferred,
                  showLabels: _showLabels,
                  selectedNodeId: _selectedNodeId,
                  onNodeTap: (node) {
                    setState(() {
                      _selectedNodeId = node.id;
                      _selectedNode = node;
                    });
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Gerando grafo de conhecimento...'),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erro: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadGraph,
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Painel lateral de detalhes
          if (_selectedNode != null)
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: _buildNodeDetailsPanel(),
            ),
        ],
      ),
      floatingActionButton: _selectedNode != null
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToNote(_selectedNode!),
              icon: const Icon(Icons.edit),
              label: const Text('Abrir Nota'),
            )
          : null,
    );
  }

  Widget _buildNodeDetailsPanel() {
    if (_selectedNode == null) return const SizedBox.shrink();
    final node = _selectedNode!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  node.label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectedNodeId = null;
                  _selectedNode = null;
                }),
              ),
            ],
          ),
          const Divider(),
          
          // Tipo
          _buildDetailRow('Tipo', _getNodeTypeName(node)),
          
          // Classe semântica
          if (node.classLocalName != null)
            _buildDetailRow('Classe', node.classLocalName!),
          
          // Se é inferido
          if (node.isInferred)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_fix_high, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('Nó inferido pelo reasoner'),
                ],
              ),
            ),
          
          // Nível na hierarquia
          if (node.hierarchyLevel > 0)
            _buildDetailRow('Nível hierárquico', '${node.hierarchyLevel}'),
          
          // Propriedades semânticas
          if (node.semanticProperties.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Propriedades Semânticas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...node.semanticProperties.entries.map((e) => _buildPropertyRow(e.key, e.value)),
          ],
          
          // Tags
          if ((node.properties['tags'] as List?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (node.properties['tags'] as List)
                  .map((tag) => Chip(
                        label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.orange[100],
                      ))
                  .toList(),
            ),
          ],
          
          // Conexões
          const SizedBox(height: 16),
          _buildConnectionsSection(node),
          
          // Ações
          const SizedBox(height: 24),
          if (node.type != 'tag') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToNote(node),
                icon: const Icon(Icons.edit),
                label: const Text('Editar Nota'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _findSimilarNodes(node),
                icon: const Icon(Icons.search),
                label: const Text('Encontrar Similares'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String uri, dynamic value) {
    final propName = uri.split('#').last;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.arrow_right, size: 16, color: Colors.grey[600]),
          Text('$propName: ', style: const TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsSection(KnowledgeNode node) {
    final graphState = ref.read(knowledgeGraphControllerProvider);
    
    return graphState.maybeWhen(
      data: (graph) {
        if (graph == null) return const SizedBox.shrink();
        
        final outgoing = graph.getOutgoingEdges(node.id);
        final incoming = graph.getIncomingEdges(node.id);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conexões (${outgoing.length + incoming.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (outgoing.isNotEmpty) ...[
              const Text('Saindo:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ...outgoing.take(5).map((e) {
                final targetNode = graph.getNode(e.targetId);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    e.isInferred ? Icons.auto_fix_high : Icons.arrow_forward,
                    size: 16,
                    color: e.isInferred ? Colors.orange : Colors.blue,
                  ),
                  title: Text(targetNode?.label ?? e.targetId, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(e.predicateLocalName, style: const TextStyle(fontSize: 11)),
                  onTap: () => setState(() {
                    _selectedNodeId = e.targetId;
                    _selectedNode = targetNode;
                  }),
                );
              }),
              if (outgoing.length > 5)
                Text('  ... e mais ${outgoing.length - 5}', style: TextStyle(color: Colors.grey[600])),
            ],
            
            if (incoming.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Chegando:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ...incoming.take(5).map((e) {
                final sourceNode = graph.getNode(e.sourceId);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    e.isInferred ? Icons.auto_fix_high : Icons.arrow_back,
                    size: 16,
                    color: e.isInferred ? Colors.orange : Colors.green,
                  ),
                  title: Text(sourceNode?.label ?? e.sourceId, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(e.predicateLocalName, style: const TextStyle(fontSize: 11)),
                  onTap: () => setState(() {
                    _selectedNodeId = e.sourceId;
                    _selectedNode = sourceNode;
                  }),
                );
              }),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  String _getNodeTypeName(KnowledgeNode node) {
    switch (node.type) {
      case 'tag': return 'Tag';
      case 'semantic_note': return 'Nota Semântica';
      case 'note': return 'Nota';
      default: return node.type;
    }
  }

  void _navigateToNote(KnowledgeNode node) {
    if (node.type == 'tag') return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(noteId: node.id),
      ),
    ).then((_) => _loadGraph());
  }

  void _findSimilarNodes(KnowledgeNode node) async {
    final controller = ref.read(knowledgeGraphControllerProvider.notifier);
    final similar = await controller.findSimilar(node.id);
    
    if (similar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum nó similar encontrado')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notas similares a "${node.label}"'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: similar.length,
            itemBuilder: (context, index) {
              final s = similar[index];
              return ListTile(
                leading: Icon(_getNodeIcon(s)),
                title: Text(s.label),
                subtitle: s.classLocalName != null ? Text(s.classLocalName!) : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedNodeId = s.id;
                    _selectedNode = s;
                  });
                },
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

  IconData _getNodeIcon(KnowledgeNode node) {
    if (node.type == 'tag') return Icons.label;
    if (node.hasSemanticType) return Icons.article;
    return Icons.note;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrar Grafo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Mostrar inferidos'),
                subtitle: const Text('Nós e arestas inferidos pelo reasoner'),
                value: _showInferred,
                onChanged: (v) => setDialogState(() => _showInferred = v),
              ),
              SwitchListTile(
                title: const Text('Mostrar tags'),
                value: _showTags,
                onChanged: (v) => setDialogState(() => _showTags = v),
              ),
              SwitchListTile(
                title: const Text('Mostrar wiki links'),
                value: _showWikiLinks,
                onChanged: (v) => setDialogState(() => _showWikiLinks = v),
              ),
              SwitchListTile(
                title: const Text('Mostrar labels'),
                value: _showLabels,
                onChanged: (v) => setDialogState(() => _showLabels = v),
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
                setState(() {});
                _loadGraph();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações do Grafo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Layout do Grafo:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Force-Directed'),
              subtitle: const Text('Layout orgânico (padrão)'),
              leading: const Icon(Icons.blur_circular),
              onTap: () => Navigator.pop(context),
            ),
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

  void _showHierarchyDialog() async {
    final controller = ref.read(knowledgeGraphControllerProvider.notifier);
    final hierarchy = await controller.getHierarchy();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hierarquia de Classes'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: hierarchy.isEmpty
              ? const Center(child: Text('Nenhuma classe definida'))
              : ListView.builder(
                  itemCount: hierarchy.length,
                  itemBuilder: (context, index) {
                    return _buildHierarchyItem(hierarchy[index], 0);
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

  Widget _buildHierarchyItem(ClassHierarchyNode node, int indent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
            setState(() => _classFilter = node.classUri);
            _loadGraph();
          },
          child: Padding(
            padding: EdgeInsets.only(left: indent * 16.0, top: 8, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.category, size: 16),
                const SizedBox(width: 8),
                Text(node.label),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${node.instanceCount}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...node.children.map((c) => _buildHierarchyItem(c, indent + 1)),
      ],
    );
  }
}
