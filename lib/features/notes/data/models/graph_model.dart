import 'dart:convert';
import '../../domain/entities/graph.dart';

class GraphModel extends Graph {
  GraphModel({
    required super.id,
    required super.nodes,
    required super.edges,
    super.metadata,
  });

  factory GraphModel.fromEntity(Graph graph) {
    return GraphModel(
      id: graph.id,
      nodes: graph.nodes.map((node) => GraphNodeModel.fromEntity(node)).toList(),
      edges: graph.edges.map((edge) => GraphEdgeModel.fromEntity(edge)).toList(),
      metadata: graph.metadata,
    );
  }

  factory GraphModel.fromJson(Map<String, dynamic> json) {
    return GraphModel(
      id: json['id'] as String,
      nodes: (json['nodes'] as List)
          .map((node) => GraphNodeModel.fromJson(node as Map<String, dynamic>))
          .toList(),
      edges: (json['edges'] as List)
          .map((edge) => GraphEdgeModel.fromJson(edge as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  factory GraphModel.fromMap(Map<String, dynamic> map) {
    return GraphModel(
      id: map['id'] as String,
      nodes: (jsonDecode(map['nodes'] as String) as List)
          .map((node) => GraphNodeModel.fromJson(node as Map<String, dynamic>))
          .toList(),
      edges: (jsonDecode(map['edges'] as String) as List)
          .map((edge) => GraphEdgeModel.fromJson(edge as Map<String, dynamic>))
          .toList(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(
              jsonDecode(map['metadata'] as String) as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nodes': nodes.map((node) => (node as GraphNodeModel).toJson()).toList(),
      'edges': edges.map((edge) => (edge as GraphEdgeModel).toJson()).toList(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nodes': jsonEncode(
          nodes.map((node) => (node as GraphNodeModel).toJson()).toList()),
      'edges': jsonEncode(
          edges.map((edge) => (edge as GraphEdgeModel).toJson()).toList()),
      'metadata': jsonEncode(metadata),
    };
  }

  Graph toEntity() {
    return Graph(
      id: id,
      nodes: nodes,
      edges: edges,
      metadata: metadata,
    );
  }
}

class GraphNodeModel extends GraphNode {
  GraphNodeModel({
    required super.id,
    required super.label,
    required super.type,
    super.properties,
  });

  factory GraphNodeModel.fromEntity(GraphNode node) {
    return GraphNodeModel(
      id: node.id,
      label: node.label,
      type: node.type,
      properties: node.properties,
    );
  }

  factory GraphNodeModel.fromJson(Map<String, dynamic> json) {
    return GraphNodeModel(
      id: json['id'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      properties: json['properties'] != null
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'properties': properties,
    };
  }

  GraphNode toEntity() {
    return GraphNode(
      id: id,
      label: label,
      type: type,
      properties: properties,
    );
  }
}

class GraphEdgeModel extends GraphEdge {
  GraphEdgeModel({
    required super.id,
    required super.sourceId,
    required super.targetId,
    required super.relationship,
    super.properties,
  });

  factory GraphEdgeModel.fromEntity(GraphEdge edge) {
    return GraphEdgeModel(
      id: edge.id,
      sourceId: edge.sourceId,
      targetId: edge.targetId,
      relationship: edge.relationship,
      properties: edge.properties,
    );
  }

  factory GraphEdgeModel.fromJson(Map<String, dynamic> json) {
    return GraphEdgeModel(
      id: json['id'] as String,
      sourceId: json['source_id'] as String,
      targetId: json['target_id'] as String,
      relationship: json['relationship'] as String,
      properties: json['properties'] != null
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_id': sourceId,
      'target_id': targetId,
      'relationship': relationship,
      'properties': properties,
    };
  }

  GraphEdge toEntity() {
    return GraphEdge(
      id: id,
      sourceId: sourceId,
      targetId: targetId,
      relationship: relationship,
      properties: properties,
    );
  }
}
