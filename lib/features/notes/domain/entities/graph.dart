class Graph {
  final String id;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, dynamic> metadata;

  Graph({
    required this.id,
    required this.nodes,
    required this.edges,
    this.metadata = const {},
  });

  Graph copyWith({
    String? id,
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
    Map<String, dynamic>? metadata,
  }) {
    return Graph(
      id: id ?? this.id,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      metadata: metadata ?? this.metadata,
    );
  }
}

class GraphNode {
  final String id;
  final String label;
  final String type;
  final Map<String, dynamic> properties;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    this.properties = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphNode &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ label.hashCode ^ type.hashCode;
}

class GraphEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String relationship;
  final Map<String, dynamic> properties;

  GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.relationship,
    this.properties = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceId == other.sourceId &&
          targetId == other.targetId &&
          relationship == other.relationship;

  @override
  int get hashCode =>
      id.hashCode ^ sourceId.hashCode ^ targetId.hashCode ^ relationship.hashCode;
}
