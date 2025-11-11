import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart' as gv;
import '../../domain/entities/graph.dart';

class GraphWidget extends StatefulWidget {
  final Graph graph;
  final Function(GraphNode)? onNodeTap;

  const GraphWidget({
    Key? key,
    required this.graph,
    this.onNodeTap,
  }) : super(key: key);

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  final gv.Graph _graph = gv.Graph();
  final gv.SugiyamaConfiguration _configuration = gv.SugiyamaConfiguration();
  late gv.SugiyamaAlgorithm _algorithm;

  @override
  void initState() {
    super.initState();
    _initializeGraph();
    
    _configuration
      ..bendPointShape = gv.CurvedBendPointShape(curveLength: 20)
      ..nodeSeparation = 50
      ..levelSeparation = 50
      ..orientation = gv.SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
    
    _algorithm = gv.SugiyamaAlgorithm(_configuration);
  }

  void _initializeGraph() {
    _graph.nodes.clear();
    _graph.edges.clear();

    // Criar mapa de nós
    final nodeMap = <String, gv.Node>{};
    
    // Adicionar nós
    for (final graphNode in widget.graph.nodes) {
      final node = gv.Node.Id(graphNode.id);
      nodeMap[graphNode.id] = node;
      _graph.addNode(node);
    }

    // Adicionar arestas
    for (final graphEdge in widget.graph.edges) {
      final sourceNode = nodeMap[graphEdge.sourceId];
      final targetNode = nodeMap[graphEdge.targetId];
      
      if (sourceNode != null && targetNode != null) {
        _graph.addEdge(sourceNode, targetNode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.graph.nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum nó no grafo',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildGraphInfo(),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.01,
            maxScale: 5.0,
            child: gv.GraphView(
              graph: _graph,
              algorithm: _algorithm,
              paint: Paint()
                ..color = Colors.blue
                ..strokeWidth = 1
                ..style = PaintingStyle.stroke,
              builder: (gv.Node node) {
                final graphNode = widget.graph.nodes.firstWhere(
                  (n) => n.id == node.key!.value,
                );
                return _buildNodeWidget(graphNode);
              },
            ),
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  Widget _buildGraphInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoChip(
            icon: Icons.circle,
            label: 'Nós',
            value: widget.graph.nodes.length.toString(),
          ),
          _buildInfoChip(
            icon: Icons.arrow_forward,
            label: 'Conexões',
            value: widget.graph.edges.length.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text('$label: '),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNodeWidget(GraphNode node) {
    Color backgroundColor;
    IconData iconData;

    switch (node.type) {
      case 'note':
        backgroundColor = Colors.blue[100]!;
        iconData = Icons.note;
        break;
      case 'tag':
        backgroundColor = Colors.orange[100]!;
        iconData = Icons.label;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        iconData = Icons.circle;
    }

    return InkWell(
      onTap: widget.onNodeTap != null ? () => widget.onNodeTap!(node) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 16),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                node.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(
            color: Colors.blue[100]!,
            icon: Icons.note,
            label: 'Nota',
          ),
          const SizedBox(width: 24),
          _buildLegendItem(
            color: Colors.orange[100]!,
            icon: Icons.label,
            label: 'Tag',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Icon(icon, size: 16),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
