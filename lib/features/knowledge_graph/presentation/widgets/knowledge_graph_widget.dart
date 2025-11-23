import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart' as gv;
import '../../domain/entities/knowledge_node.dart';

class KnowledgeGraphWidget extends StatefulWidget {
  final KnowledgeGraph graph;
  final Function(KnowledgeNode)? onNodeTap;
  final Function(SemanticEdge)? onEdgeTap;
  final bool showInferred;
  final bool showLabels;
  final Set<String>? highlightedNodes;
  final String? selectedNodeId;

  const KnowledgeGraphWidget({
    super.key,
    required this.graph,
    this.onNodeTap,
    this.onEdgeTap,
    this.showInferred = true,
    this.showLabels = true,
    this.highlightedNodes,
    this.selectedNodeId,
  });

  @override
  State<KnowledgeGraphWidget> createState() => _KnowledgeGraphWidgetState();
}

class _KnowledgeGraphWidgetState extends State<KnowledgeGraphWidget> {
  final gv.Graph _graph = gv.Graph();
  late gv.Algorithm _algorithm;
  final _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _initializeGraph();
    _algorithm = gv.FruchtermanReingoldAlgorithm();
  }

  @override
  void didUpdateWidget(KnowledgeGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph.id != widget.graph.id || 
        oldWidget.showInferred != widget.showInferred) {
      _initializeGraph();
    }
  }

  void _initializeGraph() {
    _graph.nodes.clear();
    _graph.edges.clear();

    final nodeMap = <String, gv.Node>{};

    // Filtrar nós inferidos se necessário
    final visibleNodes = widget.showInferred
        ? widget.graph.nodes
        : widget.graph.nodes.where((n) => !n.isInferred).toList();

    // Adicionar nós
    for (final kNode in visibleNodes) {
      final node = gv.Node.Id(kNode.id);
      nodeMap[kNode.id] = node;
      _graph.addNode(node);
    }

    // Filtrar e adicionar arestas
    final visibleEdges = widget.showInferred
        ? widget.graph.edges
        : widget.graph.edges.where((e) => !e.isInferred).toList();

    for (final edge in visibleEdges) {
      final source = nodeMap[edge.sourceId];
      final target = nodeMap[edge.targetId];
      if (source != null && target != null) {
        _graph.addEdge(source, target);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.graph.nodes.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatsBar(),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.01,
            maxScale: 5.0,
            child: gv.GraphView(
              graph: _graph,
              algorithm: _algorithm,
              paint: Paint()
                ..color = Colors.grey[400]!
                ..strokeWidth = 1.5
                ..style = PaintingStyle.stroke,
              builder: (gv.Node node) {
                final kNode = widget.graph.nodes.firstWhere(
                  (n) => n.id == node.key!.value,
                  orElse: () => KnowledgeNode(id: '', label: '', type: ''),
                );
                return _buildNodeWidget(kNode);
              },
            ),
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Grafo de conhecimento vazio',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie notas e adicione anotações semânticas',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final stats = widget.graph.stats;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(Icons.circle, 'Nós', stats?.totalNodes ?? widget.graph.nodes.length),
          _buildStatChip(Icons.link, 'Arestas', stats?.totalEdges ?? widget.graph.edges.length),
          if (widget.showInferred) ...[
            _buildStatChip(Icons.auto_fix_high, 'Inferidos', 
                (stats?.inferredNodes ?? 0) + (stats?.inferredEdges ?? 0)),
          ],
          _buildStatChip(Icons.label, 'Semânticos', stats?.semanticNodes ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildNodeWidget(KnowledgeNode node) {
    final isSelected = widget.selectedNodeId == node.id;
    final isHighlighted = widget.highlightedNodes?.contains(node.id) ?? false;
    final nodeStyle = _getNodeStyle(node);

    return GestureDetector(
      onTap: widget.onNodeTap != null ? () => widget.onNodeTap!(node) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? nodeStyle.color.withOpacity(0.9)
              : isHighlighted
                  ? nodeStyle.color.withOpacity(0.7)
                  : nodeStyle.color,
          borderRadius: BorderRadius.circular(nodeStyle.isCircular ? 50 : 8),
          border: Border.all(
            color: isSelected 
                ? Colors.blue[700]! 
                : node.isInferred 
                    ? Colors.orange[300]!
                    : Colors.grey[400]!,
            width: isSelected ? 3 : node.isInferred ? 2 : 1,
            style: node.isInferred ? BorderStyle.solid : BorderStyle.solid,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
              : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(nodeStyle.icon, size: 16, color: nodeStyle.iconColor),
            if (widget.showLabels) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: nodeStyle.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (node.classLocalName != null)
                      Text(
                        node.classLocalName!,
                        style: TextStyle(
                          fontSize: 9,
                          color: nodeStyle.textColor.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (node.isInferred) ...[
              const SizedBox(width: 4),
              Icon(Icons.auto_fix_high, size: 12, color: Colors.orange[700]),
            ],
          ],
        ),
      ),
    );
  }

  _NodeStyle _getNodeStyle(KnowledgeNode node) {
    // Nó de tag
    if (node.type == 'tag') {
      return _NodeStyle(
        color: Colors.orange[100]!,
        icon: Icons.label,
        iconColor: Colors.orange[700]!,
        textColor: Colors.orange[900]!,
        isCircular: true,
      );
    }

    // Nó semântico
    if (node.hasSemanticType) {
      final classColor = _getClassColor(node.ontologyClassUri!);
      return _NodeStyle(
        color: classColor.withOpacity(0.2),
        icon: _getClassIcon(node.classLocalName),
        iconColor: classColor,
        textColor: Colors.grey[900]!,
        isCircular: false,
      );
    }

    // Nó comum (nota sem anotação)
    return _NodeStyle(
      color: Colors.grey[200]!,
      icon: Icons.note,
      iconColor: Colors.grey[600]!,
      textColor: Colors.grey[800]!,
      isCircular: false,
    );
  }

  Color _getClassColor(String classUri) {
    final className = classUri.split('#').last.toLowerCase();
    
    if (className.contains('aula') || className.contains('class')) {
      return Colors.blue[600]!;
    } else if (className.contains('professor') || className.contains('pessoa')) {
      return Colors.purple[600]!;
    } else if (className.contains('disciplina') || className.contains('materia')) {
      return Colors.green[600]!;
    } else if (className.contains('evento')) {
      return Colors.pink[600]!;
    } else if (className.contains('projeto')) {
      return Colors.teal[600]!;
    }
    
    return Colors.indigo[600]!;
  }

  IconData _getClassIcon(String? className) {
    if (className == null) return Icons.article;
    
    final lower = className.toLowerCase();
    if (lower.contains('aula')) return Icons.school;
    if (lower.contains('professor')) return Icons.person;
    if (lower.contains('disciplina')) return Icons.book;
    if (lower.contains('evento')) return Icons.event;
    if (lower.contains('projeto')) return Icons.folder;
    if (lower.contains('reuniao')) return Icons.people;
    
    return Icons.article;
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem(Colors.grey[200]!, Icons.note, 'Nota'),
          _buildLegendItem(Colors.blue[100]!, Icons.school, 'Semântico'),
          _buildLegendItem(Colors.orange[100]!, Icons.label, 'Tag'),
          _buildLegendItem(
            Colors.white, 
            Icons.auto_fix_high, 
            'Inferido',
            borderColor: Colors.orange[300],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, IconData icon, String label, {Color? borderColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor ?? Colors.grey[400]!),
          ),
          child: Icon(icon, size: 14, color: borderColor ?? Colors.grey[600]),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _NodeStyle {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final bool isCircular;

  _NodeStyle({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    this.isCircular = false,
  });
}
