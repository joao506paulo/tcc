import 'dart:convert';
import '../../domain/entities/semantic_template.dart';
import '../../domain/entities/ontology_class.dart';
import '../../domain/entities/ontology_property.dart';
import 'ontology_model.dart';

class SemanticTemplateModel extends SemanticTemplate {
  SemanticTemplateModel({
    required super.id,
    required super.name,
    super.description,
    required super.mainClass,
    super.properties,
    super.defaultValues,
    super.owlDefinition,
    super.iconName,
    super.colorHex,
    super.isActive,
    required super.createdAt,
    super.updatedAt,
    super.metadata,
  });

  factory SemanticTemplateModel.fromEntity(SemanticTemplate template) {
    return SemanticTemplateModel(
      id: template.id,
      name: template.name,
      description: template.description,
      mainClass: template.mainClass,
      properties: template.properties,
      defaultValues: template.defaultValues,
      owlDefinition: template.owlDefinition,
      iconName: template.iconName,
      colorHex: template.colorHex,
      isActive: template.isActive,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      metadata: template.metadata,
    );
  }

  factory SemanticTemplateModel.fromJson(Map<String, dynamic> json) {
    return SemanticTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      mainClass: OntologyClassModel.fromJson(
        json['main_class'] as Map<String, dynamic>,
      ).toEntity(),
      properties: (json['properties'] as List?)
              ?.map((p) => OntologyPropertyModel.fromJson(p).toEntity())
              .toList() ??
          [],
      defaultValues:
          (json['default_values'] as Map?)?.cast<String, dynamic>() ?? {},
      owlDefinition: json['owl_definition'] as String?,
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  factory SemanticTemplateModel.fromMap(Map<String, dynamic> map) {
    return SemanticTemplateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      mainClass: OntologyClassModel.fromJson(
        jsonDecode(map['main_class'] as String) as Map<String, dynamic>,
      ).toEntity(),
      properties: map['properties'] != null
          ? (jsonDecode(map['properties'] as String) as List)
              .map((p) => OntologyPropertyModel.fromJson(p).toEntity())
              .toList()
          : [],
      defaultValues: map['default_values'] != null
          ? (jsonDecode(map['default_values'] as String) as Map)
              .cast<String, dynamic>()
          : {},
      owlDefinition: map['owl_definition'] as String?,
      iconName: map['icon_name'] as String?,
      colorHex: map['color_hex'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      metadata: map['metadata'] != null
          ? (jsonDecode(map['metadata'] as String) as Map).cast<String, dynamic>()
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'main_class': OntologyClassModel.fromEntity(mainClass).toJson(),
      'properties': properties
          .map((p) => OntologyPropertyModel.fromEntity(p).toJson())
          .toList(),
      'default_values': defaultValues,
      'owl_definition': owlDefinition,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'main_class': jsonEncode(OntologyClassModel.fromEntity(mainClass).toJson()),
      'properties': jsonEncode(properties
          .map((p) => OntologyPropertyModel.fromEntity(p).toJson())
          .toList()),
      'default_values': jsonEncode(defaultValues),
      'owl_definition': owlDefinition,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': jsonEncode(metadata),
    };
  }

  SemanticTemplate toEntity() {
    return SemanticTemplate(
      id: id,
      name: name,
      description: description,
      mainClass: mainClass,
      properties: properties,
      defaultValues: defaultValues,
      owlDefinition: owlDefinition,
      iconName: iconName,
      colorHex: colorHex,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }
}
